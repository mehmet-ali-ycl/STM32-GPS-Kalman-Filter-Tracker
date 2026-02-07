/*
 * kalman.h
 *
 *  Created on: Dec 24, 2025
 *      Author: acer
 */

#ifndef INC_KALMAN_H_
#define INC_KALMAN_H_

typedef struct
{
    float x[2];     // [konum, hız]
    float P[2][2];  // kovaryans
    float Q[2][2];  // process noise
    float R;        // measurement noise
} KalmanFilter;

void Kalman_Init(KalmanFilter *kf, float q_pos, float q_vel, float r);
void Kalman_SetQR(KalmanFilter *kf, float q_pos, float q_vel, float r);
float Kalman_Update(KalmanFilter *kf, float measurement);

#endif /* INC_KALMAN_H_ */
