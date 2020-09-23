# Datafield for Garmin devices
Datafield for Garmin devices that calculates the slope (or grade) of the hill you are walking on. It publishes the grade value (in %) to Garmin Connect so you can have a timeline inside your activity. It is based on the information provided by the GPS altitude (or barometric altitude on those chic devices).
My experience is that it takes around 5 minutes for the device to properly stabilize the altitude data so before that, some erratic measurements can be obtained.

It has two configuration parameters that can help you tune the calculation according to your device characteristics.
Optimal values for the parameters are those left as default (at least for my Forerunner 735xt device).

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/parameters.png)

- <b>Number of samples to estimate the slope tendency:</b> this value indicates the number of samples used to perform the linear regression of the altitude vs distance.
- <b>Coefficient to filter the altitude data from GPS:</b> this value determines the amount of filtering applied to the altitude data retrieved from the GPS signal. Higher values filter more and tend to reduce the noise; but it obviously delays the calculation yielding delays between your ride and the displayed value. This effect can be seen in the next graph. With a coefficient of 97, a smoother curve is obtained (blue line), but it can be seen that a delay is introduced that might be around 80 m (this value may depend on the actual speed). The effect of this delay is that there is a discrepancy between the value shown and your feeling.

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/filter_effect.png)

The unitary response of the filter depending on the filter coefficient is depicted in the following picture. It can be seen how as the coefficient increases, it also increases the number of samples it takes to reach close to final value (1 in this case).

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/filter_effect2.png)

From version 1.1.0 on, some data validation has been included that tries to remove (or better fix) outlier values provided by the GPS. More in concrete:
- A minimal elapsed distance (20 m) has been defined to avoid getting too close readings that could increase jitter in the calculation
- A maximal altitude increase has been defined that limits the maximum change in the altitude that corresponds to a 50% grade. This means 50% is now the maximum grade you can measure with this field (if you travel across grades above 50% you are climbing dude!)

The colour of the label "Slope" indicates the quality of the GPS coverage:

- <b>Red:</b> indicates no GPS signal is received
- <b>Orange:</b> indicates a poor quality GPS signal is received
- <b>Green:</b> indicates good quality GPS signal is received

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic1.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic2.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic3.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic4.png)