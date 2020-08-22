using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.FitContributor;
using Toybox.Position;

const __NUMSAMPLES_AVGFILT__	=	5;
const __NUMSAMPLES_LSREG__	=	10;
const __MAX_ELEVATION_STEP__ = 0.5;

class LeastSquares
{
	protected var samples;
	protected var buffer;
	protected var SamplesInBuffer;

	function initialize( NumSamples ) {
		self.samples = NumSamples;
		self.buffer = new [self.samples];
		for( var i = 0; i < self.samples; i += 1 ) {
			self.buffer[i] = {"x" => 0.0f,"y" => 0.0f};
		}
		self.SamplesInBuffer=0;
	 }

	 function add2Buffer(value)
	{
		if (self.SamplesInBuffer==0) // initialization with the first value
		{
			for( var i = 0; i < self.samples; i += 1 ) {
				self.buffer[i] = value;
			}
		}

		for( var i = 0; i < self.samples-1; i += 1 ) {
			self.buffer[i] = self.buffer[i+1];
		}
		self.buffer[self.samples-1]=value;
		if (self.SamplesInBuffer<self.samples)
		{self.SamplesInBuffer++;}

		//System.print("New value into LS buffer: ");
		//System.println(value);
	}

	function getValue()
	{
		var sumX=0.0f,sumY=0.0f,sumX2=0.0f,sumXY=0.0f;
		for( var i = 0; i < self.samples; i += 1 ) {
			sumX+=1.0f*self.buffer[i]["x"];
			sumY+=1.0f*self.buffer[i]["y"];
			sumX2+=1.0f*(self.buffer[i]["x"])*(self.buffer[i]["x"]);
			sumXY+=1.0f*(self.buffer[i]["x"])*(self.buffer[i]["y"]);
		}
		var slope;
		if (self.samples*sumX2-sumX*sumX != 0.0f){	slope=(1.0f*self.samples*sumXY-sumX*sumY)/(self.samples*sumX2-sumX*sumX);}
		else{slope=0.0f;}
		//System.print("New value from LS: ");
		//System.println(slope);
		if (self.SamplesInBuffer<self.samples){slope=0.0f;}
		return slope;
	}
}
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

	private function add2Buffer(value)
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
	}

	function getValue()
	{return self.accumulator;}
}


class SlopeView extends WatchUi.DataField {

    hidden var SlopeFilter,AltitudeFilter;
    hidden var gpsQuality;
    hidden var flagInsertNewValueToFilter;
    hidden var flagGoodData;
	hidden var LSRegression;
	hidden var prevElapsedDistance;
	hidden var prevElevation;

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

		self.prevElapsedDistance=0.0f;
		self.prevElevation=0.0f;

        // properties
        var AVGFILT_SAMPLES = self.getParameter("AVGFILT_SAMPLES", __NUMSAMPLES_AVGFILT__);
        var LSREGRESSION_SAMPLES = self.getParameter("LSREGRESSION_SAMPLES", __NUMSAMPLES_LSREG__);


        self.SlopeFilter=new MovingAverage( 1 );
        self.AltitudeFilter=new MovingAverage( AVGFILT_SAMPLES );
		self.LSRegression=new LeastSquares( LSREGRESSION_SAMPLES );

        flagInsertNewValueToFilter=false;
        flagGoodData=false;

        // this creates the field to be exported to Garmin Connect
        self.mSlopeField = createField("current_slope", SLOPE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
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

//    	var obscurityFlags = DataField.getObscurityFlags();
//
//        // Top left quadrant so we'll use the top left layout
//        if (obscurityFlags == (OBSCURE_TOP | OBSCURE_LEFT)) {
//            View.setLayout(Rez.Layouts.TopLeftLayout(dc));
//
//        // Top right quadrant so we'll use the top right layout
//        } else if (obscurityFlags == (OBSCURE_TOP | OBSCURE_RIGHT)) {
//            View.setLayout(Rez.Layouts.TopRightLayout(dc));
//
//        // Bottom left quadrant so we'll use the bottom left layout
//        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_LEFT)) {
//            View.setLayout(Rez.Layouts.BottomLeftLayout(dc));
//
//        // Bottom right quadrant so we'll use the bottom right layout
//        } else if (obscurityFlags == (OBSCURE_BOTTOM | OBSCURE_RIGHT)) {
//            View.setLayout(Rez.Layouts.BottomRightLayout(dc));
//
//        // Use the generic, centered layout
//        } else {
//            View.setLayout(Rez.Layouts.MainLayout(dc));
//        }
        View.setLayout(Rez.Layouts.MainLayout(dc));
        var labelView = View.findDrawableById("label");
        var valueView = View.findDrawableById("value");


//		System.print("DC height is: ");
//		System.println(dc.getHeight());
//
//		System.print("DC width is: ");
//		System.println(dc.getWidth());

		if (dc.getHeight() >= 110){
            labelView.locY = labelView.locY - 40;
            valueView.locY = valueView.locY + 7;
            if (dc.getWidth() >=120){valueView.setFont(Graphics.FONT_NUMBER_HOT);}
            else {valueView.setFont(Graphics.FONT_NUMBER_MILD);}
        }
        else if (dc.getHeight() >= 89){
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
		var maxAltStep=0.0f;
		var IncompatibleDevice=false;

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

		if (speed>15){maxAltStep=__MAX_ELEVATION_STEP__*2.0;}
		else{maxAltStep=__MAX_ELEVATION_STEP__;}

		if (info has :elapsedDistance){
        	if ((info.elapsedDistance  == null) or (info.elapsedDistance  <= 0.1) or (self.prevElapsedDistance==info.elapsedDistance)){
        		flagGoodData=false;
        	}
        	self.prevElapsedDistance=info.elapsedDistance; // this is to avoid entering two points with the same X coordinates to the Regressor

    	}else{
    		flagGoodData=false;
    		IncompatibleDevice=true;
		}

        if(info has :altitude ){
            if(info.altitude  == null){flagGoodData=false;}
//            else if ((info.altitude-self.prevElevation>maxAltStep) or (info.altitude-self.prevElevation<-maxAltStep)){
//            	flagGoodData=false; // this avoids entering values with too much variation in the altitude
//        	}
        	if(info.altitude  != null){self.prevElevation=info.altitude;}
        }else{
        	flagGoodData=false;
        	IncompatibleDevice=true;
    	}

		if (flagGoodData){
			self.AltitudeFilter.addSample(info.altitude);
			self.LSRegression.add2Buffer({"x"=>info.elapsedDistance,"y"=>self.AltitudeFilter.getValue()});
			flagInsertNewValueToFilter=true;
			System.print("We are at: ");
			System.print(info.elapsedDistance);
			System.println(" m from beginning");
		}

        if (flagInsertNewValueToFilter ){
        	self.SlopeFilter.addSample(self.LSRegression.getValue()*100.0f);
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        View.findDrawableById("Background").setColor(getBackgroundColor());
        var value = View.findDrawableById("value");
        var label = View.findDrawableById("label");

        if (gpsQuality==NO_GPS_DATA){label.setColor(Graphics.COLOR_RED );}
        else if (gpsQuality==GPS_POOR){label.setColor(Graphics.COLOR_ORANGE );}
        else{label.setColor(Graphics.COLOR_GREEN );}

        // Set the foreground color
		if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);

        } else {
            value.setColor(Graphics.COLOR_BLACK);
        }
        var filter_read = self.SlopeFilter.getValue();
		value.setText(filter_read.format("%.1f")+"%");
		self.mSlopeField.setData(filter_read);

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
