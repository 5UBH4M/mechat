package com.mechat.mechat

import android.os.Bundle
import android.view.WindowManager
import cl.puntito.simple_pip_mode.PipCallbackHelperActivityWrapper

class MainActivity : PipCallbackHelperActivityWrapper() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }
}
