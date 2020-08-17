# Datafield for Garmin devices
Datafield that calculates the slope [in %] that you are facing to give you an idea how hard you are climbing.
It has three configuration parameters that can help you tune the calculation according to your device characteristics.
Optimal values for the parameters are those left as default.
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/Parameters.png)
- <b>Number of samples to perform the moving average filter:</b> this value determines the amount of samples that are averaged to obtain the shown value. Higher values smooth the calculation and removes jitter, but can lead to poor dynamic response and delays.
- <b>Distance elapsed to execute the slope calculation:</b> this value indicates the distance that you need to cover to launch a new calculation. Higher values again reduces the noise in the calculation, but yields delayed responses. This parameter only affects if the method to calculate the rise parameter is the GPS altitude.
- <b>Select the method to calculate the rise:</b> this parameter defines the method used to calculate the increment in altitude on each calculation step. It can be calculated using the GPS altitude value (yields faster but more imprecise calculations) or the accumulated (des)ascent counters provided by the watch.

![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic1.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic2.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic3.png)
![alt text](https://github.com/mizamae/GarminSlopeDatafield/blob/master/manual/pic4.png)