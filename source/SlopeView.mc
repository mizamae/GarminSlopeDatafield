using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;

const __NUMSAMPLES_AVGFILT__	=	5;

class MovingAverage
{
	protected var samples;
	protected var accumulator;
	protected var buffer;
	protected var SamplesInBuffer;
	

	function initialize( NumSamples ) {
		self.samples = NumSamples;
		self.accumulator = 0.0f;
		self.buffer = new [self.samples];
		for( var i = 0; i < self.samples; i += 1 ) {
			self.buffer[i] = 0.0f;
		}
		self.SamplesInBuffer=0;
	}
	
	function add2Buffer(value)
	{
		for( var i = 0; i < self.samples-1; i += 1 ) {
			self.buffer[i] = self.buffer[i+1];
		}
		self.buffer[self.samples-1]=value;
		if (self.SamplesInBuffer<self.samples)
		{self.SamplesInBuffer++;}
	}
	
	function addSample(value)
	{
		self.accumulator += 1.0f/self.samples*(value-self.buffer[0]);
		self.add2Buffer(value);
		System.print("New value to buffer: ");
        System.println(value);
        System.print("Accumulated value: ");
        System.println(self.accumulator);
	}
	
	function getValue()
	{return self.accumulator;}
}


class SlopeView extends WatchUi.DataField {

    hidden var currAlt;
    hidden var prevAlt;
    hidden var ElapsedDistance;
	hidden var prevElapsedDistance;
    hidden var InstantSlope;
    hidden var AverageSlope;
    hidden var accumulated;
    hidden var filter;
    
    function initialize() {
        DataField.initialize();
        currAlt = 0.0f;
        prevAlt = -1000.0f;
        prevElapsedDistance = 0.0f;
        InstantSlope= 0.0f;
        AverageSlope=0.0f;
        accumulated=0;
        self.filter=new MovingAverage( __NUMSAMPLES_AVGFILT__ );
    }
	
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        if (dc.getHeight() >= 89){
            labelView.locY = labelView.locY - 30;}
            else{
            labelView.locY = labelView.locY - 20;
        }
        
        var valueView = View.findDrawableById("value");
        valueView.locY = valueView.locY + 7;

        View.findDrawableById("label").setText("Slope");
        View.findDrawableById("value").setText("---%");
        return true;
    }

    // The given info object contains all the current workout information.
    // Calculate a value and save it locally in this method.
    // Note that compute() and onUpdate() are asynchronous, and there is no
    // guarantee that compute() will be called before onUpdate().
    function compute(info) {
    	var theta=0.0f;
    	var rise=0.0f;
    	var run=0.0f;
        // See Activity.Info in the documentation for available information.
        if(info has :altitude ){
            if(info.altitude  != null){
                currAlt = info.altitude;
            } else {
                currAlt = prevAlt;
            }
        }else{currAlt = prevAlt;}
        
        if (prevAlt > -1000){
        	rise=currAlt-prevAlt;
        }else{
        	rise=0;
        }
        prevAlt = currAlt;
        
        if (info has :elapsedDistance){
        	if(info.elapsedDistance  != null){
        		ElapsedDistance=info.elapsedDistance-prevElapsedDistance;
        	}else{
        		ElapsedDistance=0.0f;
        	}
    	}else{ElapsedDistance=0.0f;}
        run=ElapsedDistance-prevElapsedDistance; // this is if elapsedDistance is measuring horizontal distance
         
        //theta=asin(rise/(ElapsedDistance-prevElapsedDistance));
        //run=(ElapsedDistance-prevElapsedDistance)*cos(theta); // this is if elapsedDistance is measuring inclined distance
        
        prevElapsedDistance=ElapsedDistance;
        
        if (run>0){
        	InstantSlope=rise/run*100;
        }else{InstantSlope=1005;}
        
        if (InstantSlope>100 or InstantSlope<-100){}
        else{
        	AverageSlope=AverageSlope+InstantSlope;
        	accumulated+=1;
        	self.filter.addSample(InstantSlope);
        }
//        System.print("New value from sensor: Rise=");
//        System.println(rise);
//        System.print("New value from sensor: Run=");
//        System.println(run);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());

        // Set the foreground color and value
        var value = View.findDrawableById("value");
        if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        
//        System.print("Moving avg filter value: ");
//        System.println(self.filter.getValue());
        
//        if (accumulated>=10)
//        {	
//        	value.setText((AverageSlope/accumulated).format("%.1f")+"%");
//        	accumulated=0;
//        }
        
		value.setText(self.filter.getValue().format("%.1f")+"%");
		
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
