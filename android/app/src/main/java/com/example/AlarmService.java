package com.example;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

public class AlarmService extends Service {
    private static final String CHANNEL_ID = "AlarmServiceChannel";
    
    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
        Notification notification = buildNotification();
        startForeground(1, notification);
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                CHANNEL_ID,
                "Alarm Service Channel",
                NotificationManager.IMPORTANCE_LOW
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(serviceChannel);
        }
    }

    private Notification buildNotification() {
        // USIAMO UN'ICONA DI SISTEMA AL POSTO DI R.mipmap.ic_launcher
        int iconResId = android.R.drawable.ic_dialog_info;
        
        return new NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Voice Chat Locale")
            .setContentText("In esecuzione in background")
            .setSmallIcon(iconResId) // Icona di sistema
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}