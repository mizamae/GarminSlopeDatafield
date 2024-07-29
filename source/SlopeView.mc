using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Math;
using Toybox.FitContributor;
using Toybox.Position;

const __NUMSAMPLES_AVGFILT__	=	5;
const __NUMSAMPLES_LSREG__	=	5;
const __MIN_DISTANCE_TO_SAMPLE__ = 20.0;	// minimum elapsed distance to include data in regressor
const __MAX_ALT_DIFFERENCE__ = 10.0; 		// maximum altitude difference between two consecutive samples

const __TESTING__ = false;
const __TEST_STR__= "20.5";

class LPF
{
	protected var kf;
	protected var OUT;
	protected var NumSamples;

	function initialize( kf ) {
		self.kf = kf;
		self.OUT = 0.0f;
		self.NumSamples= 0;
	}

	function addSample(value)
	{
		if (self.NumSamples <= 10){
			self.setValue(value);
			self.NumSamples++;
		}
		else{self.OUT = (self.OUT - value)*(self.kf) + value;}
	}

	function setParameter(value)
	{
		if ((value>0) and (value<1)){	self.kf = value;}
	}

	function setValue(value)
	{
		self.OUT = value;
	}

	function getValue()
	{
		return self.OUT;
	}
}

class LeastSquares
{
	private var samples,MinXIncr,MaxYIncr;
	private var buffer,bufferScaled;
	private var SamplesInBuffer;
	var OUT;

	function initialize( NumSamples,MinXIncr,MaxYIncr ) {
		self.samples = NumSamples;
		self.MinXIncr = MinXIncr;
		self.MaxYIncr = MaxYIncr;

		self.buffer = new [self.samples];
		for( var i = 0; i < self.samples; i += 1 ) {
			self.buffer[i] = [ 0.0f,0.0f];
		}
		self.bufferScaled=false;
		self.SamplesInBuffer=0;
		self.OUT=0.0f;

	 }

	function add2Buffer(value)
	{
		if (self.SamplesInBuffer==0) // initialization with the first value
		{
			for( var i = 0; i < self.samples; i += 1 ) {
				self.buffer[i] = value;
			}
			self.SamplesInBuffer++;
		}

		if (value[0]-self.buffer[self.samples-1][0] >= self.MinXIncr)
		{
			self.bufferScaled=false;

			if (__TESTING__){
				System.print("ADDED DATA TO BUFFER ");
				System.println(value);
			}

			for( var i = 0; i < self.samples-1; i += 1 ) {
				self.buffer[i] = self.buffer[i+1];
			}
			self.buffer[self.samples-1]=value;
			if (self.SamplesInBuffer<self.samples){self.SamplesInBuffer++;}
			else
			{
				self.cleanBuffer();
				self.updateCalculus();
				return true;
			}
		}
		return false;
	}

	private function cleanBuffer(){
		if (self.MaxYIncr >= 0.0){
			for( var i = 0; i < self.samples-1; i += 1 ) {
				if (self.buffer[i][1]-self.buffer[i+1][1]>self.MaxYIncr){
					if (__TESTING__){
						System.print("BUFFER CLEANED ON DATA ");
						System.print(i+1);
						System.print(". ORIGINAL VALUE ");
						System.println(self.buffer[i+1][1]);
					}
					self.buffer[i+1][1]=self.buffer[i][1]-self.MaxYIncr;
				}else if (self.buffer[i][1]-self.buffer[i+1][1]<-self.MaxYIncr){
					if (__TESTING__){
						System.print("BUFFER CLEANED ON DATA ");
						System.print(i+1);
						System.print(". ORIGINAL VALUE ");
						System.println(self.buffer[i+1][1]);
					}
					self.buffer[i+1][1]=self.buffer[i][1]+self.MaxYIncr;
				}
			}
		}
	}

	private function clearBuffer(){
		self.SamplesInBuffer=0;
	}

	private function updateCalculus()
	{
		var sumX=0.0f,sumY=0.0f,sumX2=0.0f,sumXY=0.0f;
		for( var i = 0; i < self.samples; i += 1 ) {
			sumX+=1.0f*(self.buffer[i][0]-self.buffer[0][0]);
			sumY+=1.0f*self.buffer[i][1];
			sumX2+=1.0f*(self.buffer[i][0]-self.buffer[0][0])*(self.buffer[i][0]-self.buffer[0][0]);
			sumXY+=1.0f*(self.buffer[i][0]-self.buffer[0][0])*(self.buffer[i][1]);
		}
		var out;
		if (self.samples*sumX2-sumX*sumX != 0.0f){	out=(1.0f*self.samples*sumXY-sumX*sumY)/(self.samples*sumX2-sumX*sumX);}
		else{out=0.0f;}
		self.OUT = out;
		//self.clearBuffer();
		if (__TESTING__)
		{
			System.print("NEW CALC BUFFER: ");
			System.println(self.buffer);
			System.print("CALC VALUE: ");
			System.println(self.OUT);
		}

	}

	function getValue()
	{
		return self.OUT;
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

    hidden var SlopeFilterPublish,AltitudeFilterDisplay;
    hidden var gpsQuality;
    hidden var flagGoodData;
	hidden var SlopeRegressionDisplay;
	hidden var prevElapsedDistance;
	hidden var flagIncompatibleDevice;
    enum{
    	NO_GPS_DATA,
    	GPS_POOR,
    	GPS_GOOD
    }
    // Field ID from resources.
	const SLOPE_FIELD_ID = 0;
	const ALTITUDE_FIELD_ID = 1;
	const MAX_SLOPE_FIELD_ID = 2;
	const MIN_SLOPE_FIELD_ID = 3;

	hidden var mSlopeField;
	hidden var mAltitudeField;
	hidden var maxSlopeField;
	hidden var minSlopeField;

	protected var max_slope_pos;
	protected var max_slope_neg;

    function initialize() {
        DataField.initialize();

		self.prevElapsedDistance=0.0f;

        // properties
        var LSREGRESSION_SAMPLES = self.getParameter("LSREGRESSION_SAMPLES", __NUMSAMPLES_LSREG__);
		var ALTITUDE_FILTER_COEFF = self.getParameter("ALTITUDE_FILTER_COEFF", 50)/100.0f;


        self.SlopeFilterPublish=new MovingAverage( __NUMSAMPLES_AVGFILT__ );
        self.AltitudeFilterDisplay=new LPF( ALTITUDE_FILTER_COEFF );
		self.SlopeRegressionDisplay=new LeastSquares( LSREGRESSION_SAMPLES , __MIN_DISTANCE_TO_SAMPLE__ , __MAX_ALT_DIFFERENCE__);

        flagGoodData=false;
		flagIncompatibleDevice=false;

		self.max_slope_pos = 0.0;
		self.max_slope_neg = 0.0;

        // this creates the field to be exported to Garmin Connect
        self.mSlopeField = createField("current_slope", SLOPE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"%" });
        self.mAltitudeField = createField("filtered_altitude", ALTITUDE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_RECORD, :units=>"m" });
		self.maxSlopeField = createField("max_slope", MAX_SLOPE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });
		self.minSlopeField = createField("min_slope", MIN_SLOPE_FIELD_ID, FitContributor.DATA_TYPE_FLOAT, { :mesgType=>FitContributor.MESG_TYPE_SESSION, :units=>"%" });
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

   		var width = dc.getWidth();
		var height = dc.getHeight();
		//var font = WatchUi.loadResource(Rez.Fonts.customFont);

		if (height >= 240){
           View.setLayout(Rez.Layouts.BigLayout1(dc));
       	}else if (height > 120){
			if (width==height){View.setLayout(Rez.Layouts.MediumLayout1(dc));}
			else {View.setLayout(Rez.Layouts.BigLayout2(dc));}
       	}else if (height > 82){
			if (width==height){View.setLayout(Rez.Layouts.MediumLayout1(dc));}
			else {View.setLayout(Rez.Layouts.MediumLayout2(dc));}
       	}else if (height > 69){View.setLayout(Rez.Layouts.SmallLayout(dc));}
		else {View.setLayout(Rez.Layouts.MicroLayout(dc));}

        var labelView = View.findDrawableById("label") as Toybox.WatchUi.Text;
        var valueView = View.findDrawableById("value") as Toybox.WatchUi.Text;

		if (__TESTING__)
		{
			System.print("DC height is: ");
			System.println(dc.getHeight());

			System.print("DC width is: ");
			System.println(dc.getWidth());
		}



        (View.findDrawableById("label") as Toybox.WatchUi.Text).setText("Slope");
        if (__TESTING__)
        {(View.findDrawableById("value") as Toybox.WatchUi.Text).setText(__TEST_STR__);}
        else{(View.findDrawableById("value") as Toybox.WatchUi.Text).setText("---%");}
        //return true;
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

    	if (info has :currentLocationAccuracy){
    		if (info.currentLocationAccuracy  != null) {
    			if (info.currentLocationAccuracy>=Position.QUALITY_USABLE){
    				gpsQuality=GPS_GOOD;
    			}else if (info.currentLocationAccuracy>=Position.QUALITY_POOR){
    				gpsQuality=GPS_POOR;
    			}else{
    				gpsQuality=NO_GPS_DATA;
    				flagGoodData=false;
    				System.println("BAD DATA DUE TO GPS QUALITY");
				}
    		}else{
    			gpsQuality=NO_GPS_DATA;
    			flagGoodData=false;
    			System.println("BAD DATA DUE TO GPS QUALITY");
			}
    	}else{
    		gpsQuality=NO_GPS_DATA;
    		flagGoodData=false;
    		System.println("BAD DATA DUE TO GPS QUALITY");
		}

		if (info has :currentSpeed){
			if(info.currentSpeed  != null){speed=info.currentSpeed*3.6;}
			else{speed=5.0f;}
		}else{speed=5.0f;}

		if (speed<1.0f){flagGoodData=false;}
//		else{self.AltitudeFilterDisplay.setParameter(0.97);}

		if (info has :elapsedDistance){
        	if ((info.elapsedDistance  == null) or (info.elapsedDistance  <= 0.1) or (self.prevElapsedDistance==info.elapsedDistance)){
        		flagGoodData=false;
        		//System.print("BAD DATA DUE TO ELAPSED DISTANCE ");
        		//System.println(info.elapsedDistance);
        	}
        	self.prevElapsedDistance=info.elapsedDistance; // this is to avoid entering two points with the same X coordinates to the Regressor

    	}else{
    		flagGoodData=false;
    		flagIncompatibleDevice=true;
		}

        if(info has :altitude ){
            if(info.altitude  == null){flagGoodData=false;}
        }else{
        	flagGoodData=false;
        	flagIncompatibleDevice=true;
    	}

		if (flagGoodData){
			// LOAD DATA TO DISPLAY
			self.AltitudeFilterDisplay.addSample(info.altitude);
			if (self.SlopeRegressionDisplay.add2Buffer([info.elapsedDistance,self.AltitudeFilterDisplay.getValue()])){
				// PUBLISH DATA TO GARMIN CONNECT
	        	self.SlopeFilterPublish.addSample(self.SlopeRegressionDisplay.getValue()*100.0f);
				self.mSlopeField.setData(self.SlopeFilterPublish.getValue());
				self.mAltitudeField.setData(self.AltitudeFilterDisplay.getValue());
				if (self.SlopeFilterPublish.getValue() > self.max_slope_pos)
				{
					self.max_slope_pos = self.SlopeFilterPublish.getValue();
					self.maxSlopeField.setData(self.max_slope_pos);
				}
				if (self.SlopeFilterPublish.getValue() < self.max_slope_neg)
				{
					self.max_slope_neg = self.SlopeFilterPublish.getValue();
					self.minSlopeField.setData(self.max_slope_neg);
				}
			}
        }
    }

    // Display the value you computed here. This will be called
    // once a second when the data field is visible.
    function onUpdate(dc) {
        // Set the background color
        (View.findDrawableById("Background") as Toybox.WatchUi.Text).setColor(getBackgroundColor());
        var value = View.findDrawableById("value") as Toybox.WatchUi.Text;
        var label = View.findDrawableById("label") as Toybox.WatchUi.Text;
		var pc = View.findDrawableById("pc") as Toybox.WatchUi.Text;
		pc.setText("%");

        if (gpsQuality==NO_GPS_DATA){label.setColor(Graphics.COLOR_RED );}
        else if (gpsQuality==GPS_POOR){label.setColor(Graphics.COLOR_ORANGE );}
        else{label.setColor(Graphics.COLOR_GREEN );}

        // Set the foreground color
		if (getBackgroundColor() == Graphics.COLOR_BLACK) {
            value.setColor(Graphics.COLOR_WHITE);
			pc.setColor(Graphics.COLOR_WHITE);
        } else {
            value.setColor(Graphics.COLOR_BLACK);
			pc.setColor(Graphics.COLOR_BLACK);
        }
		var reading = self.SlopeRegressionDisplay.getValue()*100.0f;
		value.setText(reading.format("%.1f"));

        // Call parent's onUpdate(dc) to redraw the layout
        View.onUpdate(dc);
    }

}
