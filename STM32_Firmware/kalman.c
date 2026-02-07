#include "kalman.h"

// Zaman adımı (1 saniye).
// Eğer GPS saniyede 10 veri gönderiyorsa bunu 0.1f yapmalısın.
#define DT 1.0f

// === 1. BAŞLATMA FONKSİYONU ===
// Sistemi ilk açtığında başlangıç değerlerini atar.
void Kalman_Init(KalmanFilter *kf, float q_pos, float q_vel, float r)
{
    kf->x[0] = 0.0f;
    kf->x[1] = 0.0f;

    kf->P[0][0] = 1.0f; kf->P[0][1] = 0.0f;
    kf->P[1][0] = 0.0f; kf->P[1][1] = 1.0f;

    // 🔴 ARTIK SABİT DEĞİL
    kf->Q[0][0] = q_pos;
    kf->Q[0][1] = 0.0f;
    kf->Q[1][0] = 0.0f;
    kf->Q[1][1] = q_vel;

    kf->R = r;
}


// === 2. GÜNCELLEME VE TAHMİN (HEPSİ BİR ARADA) ===
// Bu fonksiyonu her yeni veri geldiğinde çağıracaksın.
float Kalman_Update(KalmanFilter *kf, float z)
{
    float x_pred[2];
    float P_pred[2][2];

    // --- ADIM A: TAHMİN (PREDICTION) ---
    // Fiziksel modele göre bir sonraki adımı öngör
    x_pred[0] = kf->x[0] + DT * kf->x[1];
    x_pred[1] = kf->x[1];

    // Hata matrisini (P) genişlet
    P_pred[0][0] = kf->P[0][0] + DT*(kf->P[1][0] + kf->P[0][1]) + DT*DT*kf->P[1][1] + kf->Q[0][0];
    P_pred[0][1] = kf->P[0][1] + DT*kf->P[1][1];
    P_pred[1][0] = kf->P[1][0] + DT*kf->P[1][1];
    P_pred[1][1] = kf->P[1][1] + kf->Q[1][1];

    // --- ADIM B: KALMAN KAZANCI (KALMAN GAIN) ---
    // Tahmin mi daha güvenilir, ölçüm mü? K bunu belirler.
    float S = P_pred[0][0] + kf->R;
    float K0 = P_pred[0][0] / S;
    float K1 = P_pred[1][0] / S;

    // --- ADIM C: GÜNCELLEME (UPDATE) ---
    // Tahmin ile Gerçek Ölçüm (z) arasındaki farkı bul ve düzelt
    float y = z - x_pred[0]; // İnovasyon (Hata farkı)

    kf->x[0] = x_pred[0] + K0 * y;
    kf->x[1] = x_pred[1] + K1 * y;

    kf->P[0][0] = (1 - K0) * P_pred[0][0];
    kf->P[0][1] = (1 - K0) * P_pred[0][1];
    kf->P[1][0] = -K1 * P_pred[0][0] + P_pred[1][0];
    kf->P[1][1] = -K1 * P_pred[0][1] + P_pred[1][1];

    return kf->x[0];  // Filtrelenmiş en son konumu döndür
}
void Kalman_SetQR(KalmanFilter *kf, float q_pos, float q_vel, float r)
{
    kf->Q[0][0] = q_pos;
    kf->Q[1][1] = q_vel;
    kf->R = r;
}

