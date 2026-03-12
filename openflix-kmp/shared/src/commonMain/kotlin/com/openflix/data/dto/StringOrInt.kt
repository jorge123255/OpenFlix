package com.openflix.data.dto

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

@Serializable(with = StringOrIntSerializer::class)
data class StringOrInt(
    val stringValue: String,
    val intValue: Int
) {
    companion object {
        fun fromString(value: String) = StringOrInt(value, value.toIntOrNull() ?: 0)
        fun fromInt(value: Int) = StringOrInt(value.toString(), value)
    }
}

object StringOrIntSerializer : KSerializer<StringOrInt> {
    override val descriptor = PrimitiveSerialDescriptor("StringOrInt", PrimitiveKind.STRING)

    override fun serialize(encoder: Encoder, value: StringOrInt) {
        encoder.encodeString(value.stringValue)
    }

    override fun deserialize(decoder: Decoder): StringOrInt {
        val jsonDecoder = decoder as? JsonDecoder
        if (jsonDecoder != null) {
            val element = jsonDecoder.decodeJsonElement()
            if (element is JsonPrimitive) {
                val intVal = element.intOrNull
                if (intVal != null) return StringOrInt.fromInt(intVal)
                return StringOrInt.fromString(element.content)
            }
        }
        val str = decoder.decodeString()
        return StringOrInt.fromString(str)
    }
}
