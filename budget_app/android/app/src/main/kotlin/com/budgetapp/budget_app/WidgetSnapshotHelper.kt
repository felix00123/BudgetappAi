package com.budgetapp.budget_app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class WidgetProgressItem(
    val id: String,
    val name: String,
    val icon: String,
    val progress: Int,
    val subtitle: String,
)

object WidgetSnapshotHelper {
    private const val HOME_WIDGET_PREFS = "HomeWidgetPreferences"
    const val GOALS_DATA_KEY = "goals_widget_data"
    const val LOANS_DATA_KEY = "loans_widget_data"

    fun readGoals(context: Context): List<WidgetProgressItem> =
        readItems(context, GOALS_DATA_KEY)

    fun readLoans(context: Context): List<WidgetProgressItem> =
        readItems(context, LOANS_DATA_KEY)

    fun findGoal(context: Context, id: String): WidgetProgressItem? =
        readGoals(context).firstOrNull { it.id == id }

    fun findLoan(context: Context, id: String): WidgetProgressItem? =
        readLoans(context).firstOrNull { it.id == id }

    private fun readItems(context: Context, key: String): List<WidgetProgressItem> {
        val prefs = context.getSharedPreferences(HOME_WIDGET_PREFS, Context.MODE_PRIVATE)
        val raw = prefs.getString(key, "[]") ?: "[]"
        return parseItems(raw)
    }

    fun parseItems(raw: String): List<WidgetProgressItem> {
        val items = mutableListOf<WidgetProgressItem>()
        try {
            val array = JSONArray(raw)
            for (index in 0 until array.length()) {
                val obj = array.getJSONObject(index)
                items.add(obj.toItem())
            }
        } catch (_: Exception) {
            // Ignore malformed snapshot data.
        }
        return items
    }

    private fun JSONObject.toItem(): WidgetProgressItem =
        WidgetProgressItem(
            id = getString("id"),
            name = getString("name"),
            icon = optString("icon", "🎯"),
            progress = optInt("progress", 0).coerceIn(0, 100),
            subtitle = optString("subtitle", ""),
        )
}

object ProgressWidgetConfigStore {
    private const val PREFS = "ProgressWidgetConfig"

    fun save(
        context: Context,
        appWidgetId: Int,
        type: String,
        itemId: String,
        name: String,
        icon: String,
    ) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(key(appWidgetId, "type"), type)
            .putString(key(appWidgetId, "item_id"), itemId)
            .putString(key(appWidgetId, "name"), name)
            .putString(key(appWidgetId, "icon"), icon)
            .apply()
    }

    fun readType(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "type"), null)

    fun readItemId(context: Context, appWidgetId: Int): String? =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(key(appWidgetId, "item_id"), null)

    fun clear(context: Context, appWidgetId: Int) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .remove(key(appWidgetId, "type"))
            .remove(key(appWidgetId, "item_id"))
            .remove(key(appWidgetId, "name"))
            .remove(key(appWidgetId, "icon"))
            .apply()
    }

    private fun key(appWidgetId: Int, suffix: String): String =
        "widget_${appWidgetId}_$suffix"
}
