# Datafield for Garmin devices
Datafield for Garmin devices that calculates the slope (or grade) of the hill you are walking on.
It has two configuration parameters that can help you tune the calculation according to your device characteristics.
Optimal values for the parameters are those left as default (at least for my Forerunner 735xt device).

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/parameters.png)

- <b>Number of samples to estimate the slope tendency:</b> this value indicates the number of samples used to perform the linear regression of the altitude vs distance.
- <b>Coefficient to filter the altitude data from GPS:</b> this value determines the amount of filtering applied to the altitude data retrieved from the GPS signal. Higher values filter more and tend to reduce the noise; but it obviously delays the calculation yielding delays between your ride and the displayed value. This effect can be seen in the next graph

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/filter_effect.png)

The colour of the label "Slope" indicates the quality of the GPS coverage:

- <b>Red:</b> indicates no GPS signal is received
- <b>Orange:</b> indicates a poor quality GPS signal is received
- <b>Green:</b> indicates good quality GPS signal is received

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic1.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic2.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic3.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic4.png)