using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.FitContributor;
using Toybox.Position;

const __NUMSAMPLES_AVGFILT__	=	5;
const __METERS_TO_UPDATE__	=	5;

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
        //System.print("Accumulated value: ");
        //System.println(self.accumulator);
	}
	
	function getValue()
	{return self.accumulator;}
}


class SlopeView extends WatchUi.DataField {

    hidden var currAlt;
    hidden var prevAlt;
    hidden var ElapsedDistance;
	hidden var prevElapsedDistance;
    hidden var filter;
    hidden var DISTANCE2UPDATE;
    hidden var deltaRise;
    hidden var gpsQuality;
    hidden var flagRiseWithAltitude;
    hidden var flagInsertNewValueToFilter;
    hidden var flagGoodData;
    hidden var prevTotalAscent,prevTotalDescent;
    
    enum{
    	NO_GPS_DATA,
    	GPS_POOR,
    	GPS_GOOD
    }
    // Field ID from resources.
	const SLOPE_FIELD_ID = 0;
	hidden var mSlopeField;

    function initialize() {
        DataField.initialize();
        currAlt = 0.0f;
        prevAlt = -1000.0f;
        prevTotalAscent=0.0f;
        prevTotalDescent=0.0f;
        deltaRise=0.25;
        prevElapsedDistance = 0.0f;
        
        var AVGFILT_SAMPLES = self.getParameter("AVGFILT_SAMPLES", __NUMSAMPLES_AVGFILT__);
        DISTANCE2UPDATE = self.getParameter("DISTANCE2UPDATE", __METERS_TO_UPDATE__);
        self.filter=new MovingAverage( __NUMSAMPLES_AVGFILT__ );
        
        flagRiseWithAltitude=false;
        flagInsertNewValueToFilter=false;
        flagGoodData=false;
        
        // this creates the field to be exported to Garmin Connect
        mSlopeField = createField("current_slope", SLOPE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
    }
	
	function getParameter(paramName, defaultValue)
	{
	    var paramValue = Application.Properties.getValue(paramName);
	    if (paramValue == null) {
	      paramValue = defaultValue;
	      Application.Properties.setValue(paramName, defaultValue);
	    }
	    
	    if (paramValue == null) { return 0; }
	    return paramValue;
	}
  
    // Set your layout here. Anytime the size of obscurity of
    // the draw context is changed this will be called.
    function onLayout(dc) {
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        var valueView = View.findDrawableById("value");
        
        
        if (dc.getHeight() >= 89){
            labelView.locY = labelView.locY - 30;
            valueView.locY = valueView.locY + 7;
            valueView.setFont(Graphics.FONT_NUMBER_HOT);
        }
        else{
        	labelView.locY = labelView.locY - 20;
        	valueView.locY = valueView.locY + 20;
        	valueView.setFont(Graphics.FONT_NUMBER_MILD);
        }
        

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
    	var speed=0.0f;
    	var InstantSlope=0.0f;
    	
    	flagGoodData=true;
    	flagInsertNewValueToFilter=false;
    	
    	if (info has :currentLocationAccuracy){
    		if (info.currentLocationAccuracy  != null) {
    			if (info.currentLocationAccuracy>=Position.QUALITY_USABLE){
    				gpsQuality=GPS_GOOD;
    			}else if (info.currentLocationAccuracy>=Position.QUALITY_POOR){
    				gpsQuality=GPS_POOR;
    			}else{
    				gpsQuality=NO_GPS_DATA;
    				flagGoodData=false;
				}
    		}else{
    			gpsQuality=NO_GPS_DATA;
    			flagGoodData=false;
			}
    	}else{
    		gpsQuality=NO_GPS_DATA;
    		flagGoodData=false;
		}
    	
		if (info has :currentSpeed){
			if(info.currentSpeed  != null){speed=info.currentSpeed*3.6;}
			else{speed=5;}
		}else{speed=5;}
		
		if (info has :elapsedDistance){
        	if(info.elapsedDistance  != null){
        		ElapsedDistance=info.elapsedDistance;
        	}else{
        		ElapsedDistance=0.0f;
        		flagGoodData=false;
        	}
    	}else{
    		ElapsedDistance=0.0f;
    		flagGoodData=false;
		}
        run=ElapsedDistance-prevElapsedDistance; // this is if elapsedDistance is measuring horizontal distance
        
        if (run == 0.0f){flagGoodData=false;}
        
        //theta=asin(rise/(ElapsedDistance-prevElapsedDistance));
        //run=(ElapsedDistance-prevElapsedDistance)*cos(theta); // this is if elapsedDistance is measuring inclined distance
        
        if (flagRiseWithAltitude){
	        if(info has :altitude ){
	            if(info.altitude  != null){
	                currAlt = info.altitude;
	            } else {
	                currAlt = prevAlt;
	                flagGoodData=false;
	            }
	        }else{
	        	currAlt = prevAlt;
	        	flagGoodData=false;
        	}
	        
	        if (prevAlt > -1000){
	        	rise=currAlt-prevAlt;
	        }else{
	        	rise=0;
	        }
	        
	        if ((speed>=15) and (run >= DISTANCE2UPDATE)){
	        	flagInsertNewValueToFilter=true;
	        	System.println("High speed mode");
	        }else if ((speed>0) and(speed<15) and (run >= 2*DISTANCE2UPDATE)){
	        	flagInsertNewValueToFilter=true;
	        	System.println("Low speed mode");
	        }else{run=0.0f;} 
	        //prevAlt = currAlt;
        }else{
        	if ((info has :totalAscent) and (info has :totalDescent)){
	            if ((info.totalAscent != null) and (info.totalDescent != null)){
        			if (info.totalAscent-prevTotalAscent >= deltaRise){
        				rise=info.totalAscent-prevTotalAscent;
        				flagInsertNewValueToFilter=true;
        			}else if (info.totalDescent-prevTotalDescent >= deltaRise){
        				rise=-(info.totalDescent-prevTotalDescent);
        				flagInsertNewValueToFilter=true;
        			}else{
        				rise=0.0;
        				flagInsertNewValueToFilter=false;
    				}
    			}
			}
        }

		if (flagInsertNewValueToFilter and (run != 0.0f)){InstantSlope=rise/run*100;}
		else if (run > 80){ // this is to update the slope value if rise is close to 0
			InstantSlope=0.0f;
			flagInsertNewValueToFilter=true;
		}
        	
        
        if (flagInsertNewValueToFilter and flagGoodData){
        	self.filter.addSample(InstantSlope);
        	prevElapsedDistance=info.elapsedDistance;
        	prevTotalAscent=info.totalAscent;
        	prevTotalDescent=info.totalDescent;
        	prevAlt = currAlt;
        	System.print("Rise is : ");
	        System.println(rise);
	        System.print("Run is : ");
	        System.println(run);
        }
        
        
        //System.print("GPS quality is : ");
        //System.println(gpsQuality);
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());
        var value = View.findDrawableById("value");
        var label = View.findDrawableById("label");
        
        // Set the foreground color
		if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
            label.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
            label.setColor(Graphics.COLOR_BLACK);
        }
        var filter_read = self.filter.getValue();
		value.setText(filter_read.format("%.1f")+"%");
		mSlopeField.setData(filter_read);
		
        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
