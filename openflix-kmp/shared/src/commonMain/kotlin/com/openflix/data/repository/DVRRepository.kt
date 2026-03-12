package com.openflix.data.repository

import com.openflix.data.network.OpenFlixApi
import com.openflix.domain.model.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

class DVRRepository(private val api: OpenFlixApi) {
    private val _recordings = MutableStateFlow<List<Recording>>(emptyList())
    val recordings: StateFlow<List<Recording>> = _recordings.asStateFlow()

    private val _scheduled = MutableStateFlow<List<Recording>>(emptyList())
    val scheduled: StateFlow<List<Recording>> = _scheduled.asStateFlow()

    suspend fun loadRecordings(): List<Recording> {
        val response = api.getRecordings()
        val list = response.allRecordings.map { it.toDomain() }
        _recordings.value = list.filter { it.status == RecordingStatus.COMPLETED }
        _scheduled.value = list.filter { it.status == RecordingStatus.SCHEDULED }
        return list
    }

    suspend fun getRecording(id: Int): Recording {
        return api.getRecording(id).toDomain()
    }

    suspend fun recordFromProgram(channelId: String, programId: String): Recording {
        return api.recordFromProgram(channelId, programId).toDomain()
    }

    suspend fun deleteRecording(id: Int) {
        api.deleteRecording(id)
        _recordings.value = _recordings.value.filter { it.id != id }
        _scheduled.value = _scheduled.value.filter { it.id != id }
    }

    suspend fun getRecordingStream(id: Int): String {
        return api.getRecordingStream(id).url
    }

    suspend fun getSeriesRules(): List<SeriesRule> {
        return api.getSeriesRules().rules.map { it.toDomain() }
    }

    suspend fun deleteSeriesRule(id: Int) {
        api.deleteSeriesRule(id)
    }

    val completedRecordings: List<Recording> get() =
        _recordings.value.filter { it.status == RecordingStatus.COMPLETED }

    val activeRecordings: List<Recording> get() =
        _recordings.value.filter { it.status == RecordingStatus.RECORDING }
}
