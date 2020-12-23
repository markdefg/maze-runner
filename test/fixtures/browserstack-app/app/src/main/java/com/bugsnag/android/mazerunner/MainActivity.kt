package com.bugsnag.android.mazerunner

import android.os.Build
import android.os.Bundle
import android.support.v7.app.AppCompatActivity
import android.util.Log
import android.widget.Button
import android.widget.EditText
import java.lang.Exception
import java.net.URL

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        val button = findViewById<Button>(R.id.trigger_error)
        button.setOnClickListener {
            val metadata = findViewById<EditText>(R.id.metadata).text.toString()

            Thread {
                Log.i("Steve", "GETting google.com")
                Log.i("Steve", URL("http://google.com").readText() + "\n\n\n\n")

                Log.i("Steve", "GETting bs-local.com:8080")
                Log.i("Steve", URL("http://bs-local.com:8080").readText())

            }.start()
        }
    }
}
