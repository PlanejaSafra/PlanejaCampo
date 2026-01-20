package com.noverde.planejachuva.widget

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import com.noverde.planejachuva.R

class RainWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            val rainValue = widgetData.getString("last_rain_val", "--")
            val rainDate = widgetData.getString("last_rain_date", "Sem dados")
            val lastUpdate = widgetData.getString("last_update_ts", "Atualizado agora")

            views.setTextViewText(R.id.widget_rain_value, rainValue)
            views.setTextViewText(R.id.widget_rain_date, rainDate)
            views.setTextViewText(R.id.widget_last_update, lastUpdate)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
