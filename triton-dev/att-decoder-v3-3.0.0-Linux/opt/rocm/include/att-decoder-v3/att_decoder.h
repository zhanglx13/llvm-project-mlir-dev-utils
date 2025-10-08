// MIT License
//
// Copyright (c) 2024 Advanced Micro Devices, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

#pragma once

#ifdef __cplusplus
#include <cstddef>
#include <cstdint>
extern "C" {
#else
#include <stddef.h>
#include <stdint.h>
#endif

typedef enum
{
    ROCPROFILER_ATT_DECODER_STATUS_SUCCESS = 0,
    ROCPROFILER_ATT_DECODER_STATUS_ERROR,
    ROCPROFILER_ATT_DECODER_STATUS_ERROR_OUT_OF_RESOURCES,
    ROCPROFILER_ATT_DECODER_STATUS_ERROR_INVALID_ARGUMENT,
    ROCPROFILER_ATT_DECODER_STATUS_ERROR_INVALID_SHADER_DATA,
    ROCPROFILER_ATT_DECODER_STATUS_LAST
} rocprofiler_att_decoder_status_t;

typedef enum
{
    ROCPROFILER_ATT_DECODER_INFO_NONE = 0,
    ROCPROFILER_ATT_DECODER_INFO_DATA_LOST,
    ROCPROFILER_ATT_DECODER_INFO_STITCH_INCOMPLETE,
    ROCPROFILER_ATT_DECODER_INFO_LAST
} rocprofiler_att_decoder_info_t;

typedef struct {
    size_t addr;
    size_t marker_id;
} pcinfo_t;

typedef struct
{
    int64_t time;
    uint16_t events0;
    uint16_t events1;
    uint16_t events2;
    uint16_t events3;
    uint8_t CU;
    uint8_t bank;
} att_perfevent_t;

typedef struct
{
    pcinfo_t pc;
    uint64_t time;
    uint8_t  se;
    uint8_t  cu;
    uint8_t  simd;
    uint8_t  slot;
    uint32_t start : 1;
    uint32_t _rsvd : 31;
} att_occupancy_info_v2_t;

typedef struct
{
    int32_t type;
    int32_t duration;
} att_wave_state_t;

typedef struct
{
    uint32_t category : 8;
    uint32_t stall    : 24;
    int32_t duration;
    int64_t time;
    pcinfo_t pc;
} att_wave_instruction_t;

typedef enum
{
    ATT_WAVE_STATE_EMPTY = 0,
    ATT_WAVE_STATE_IDLE,
    ATT_WAVE_STATE_EXEC,
    ATT_WAVE_STATE_WAIT,
    ATT_WAVE_STATE_STALL,
    ATT_WAVE_STATE_LAST,
} att_waveslot_state_t;

typedef enum
{
    ATT_INST_NONE = 0,
    ATT_INST_SMEM,
    ATT_INST_SALU,
    ATT_INST_VMEM,
    ATT_INST_FLAT,
    ATT_INST_LDS,
    ATT_INST_VALU,
    ATT_INST_JUMP,
    ATT_INST_NEXT,
    ATT_INST_IMMED,
    ATT_INST_CONTEXT,
    ATT_INST_MESSAGE,
    ATT_INST_BVH,
    ATT_INST_LAST
} att_wave_inst_category_t;

typedef struct
{
    uint8_t cu;
    uint8_t simd;
    uint8_t wave_id;
    uint8_t contexts;

    uint32_t _rsvd;
    size_t traceID;

    int64_t begin_time;
    int64_t end_time;

    size_t timeline_size;
    size_t instructions_size;
    att_wave_state_t* timeline_array;
    att_wave_instruction_t* instructions_array;
} att_wave_data_t;

/**
 * @brief Callback for rocprofiler to return ISA to decoder.
 * The caller must copy a desired instruction on isa_instruction and source_reference,
 * while obeying the max length passed by the caller.
 * If the caller's length is insufficient, then this function writes the minimum sizes to isa_size
 * and source_size and returns ROCPROFILER_ATT_DECODER_STATUS_ERROR_OUT_OF_RESOURCES.
 * If call returns _SUCCESS, isa_size and source_size must be written with bytes used.
 * @param[out] instruction Where to copy the ISA line to.
 * @param[out] memory_size (Auto) The number of bytes to next instruction. 0 for custom ISA.
 * @param[inout] size Size of returned ISA string.
 * @param[in] address The code object ID and offset from base vaddr.
 * If marker_id == 0, this parameter is raw virtual address with no codeobj ID information.
 * @param[in] userdata Arbitrary data pointer to be sent back to the user via callback.
 * @retval ROCPROFILER_ATT_DECODER_STATUS_SUCCESS on success.
 * @retval ROCPROFILER_ATT_DECODER_STATUS_ERROR on generic error.
 * @retval ROCPROFILER_ATT_DECODER_STATUS_ERROR_INVALID_ARGUMENT for invalid address.
 * @retval ROCPROFILER_ATT_DECODER_STATUS_ERROR_OUT_OF_RESOURCES for insufficient isa_size.
*/
typedef rocprofiler_att_decoder_status_t(*rocprofiler_att_decoder_isa_callback_t)(
    char* instruction,
    uint64_t* memory_size,
    uint64_t* size,
    pcinfo_t address,
    void* userdata
);

typedef enum {
    ROCPROFILER_ATT_DECODER_TYPE_GFXIP = 0,  // Record is a size_t representing the gfxip
    ROCPROFILER_ATT_DECODER_TYPE_OCCUPANCY,  // Record is pointer to att_occupancy_info_v2_t
    ROCPROFILER_ATT_DECODER_TYPE_PERFEVENT,  // Record is pointer to att_perfevent_t
    ROCPROFILER_ATT_DECODER_TYPE_WAVE,       // Record is pointer to att_wave_data_t
    ROCPROFILER_ATT_DECODER_TYPE_INFO,       // Record is pointer to rocprofiler_att_decoder_info_t
    ROCPROFILER_ATT_DECODER_TYPE_DEBUG,      // Debug
    ROCPROFILER_ATT_DECODER_TYPE_LAST
} rocprofiler_att_decoder_record_type_t;

/**
 * @brief Callback for rocprofiler to return traces back to rocprofiler.
 * @param[in] trace_type_id One of rocprofiler_att_decoder_record_type_t
 * @param[in] shader_engine_id The ID of shader engine or trace callback number. -1 for N/A.
 * @param[in] trace_events A pointer to sequence of events, of size trace_size.
 * @param[in] trace_size The number of events in the trace.
 * @param[in] userdata Arbitrary data pointer to be sent back to the user via callback.
*/
typedef rocprofiler_att_decoder_status_t(*rocprofiler_att_decoder_trace_callback_t)(
    rocprofiler_att_decoder_record_type_t record_type_id,
    int shader_engine_id,
    void* trace_events,
    uint64_t trace_size,
    void* userdata
);

/**
 * @brief Callback for the decoder to retrieve Shader Engine data. Return zero to end parsing.
 * @param[out] shader_engine_id The ID of given shader engine.
 * @param[out] buffer The buffer to fill up with SE data.
 * @param[out] buffer_size The space available in the buffer.
 * @param[in] userdata Arbitrary data pointer to be sent back to the user via callback.
 * @returns Number of bytes remaining in shader engine.
 * @retval 0 if no more SE data is available. Parsing will stop.
 * @retval buffer_size if the buffer does not hold enough data for the current shader engine.
 * @retval 0 > ret > buffer_size for partially filled buffer, and caller moves over to next SE.
*/
typedef uint64_t(*rocprofiler_att_decoder_se_data_callback_t)(
    int* shader_engine_id,
    uint8_t** buffer,
    uint64_t* buffer_size,
    void* userdata
);

/**
 * @brief Iterate over all event coordinates for a given agent_t and event_t.
 * @param[in] se_data_callback Callback to return shader engine data from.
 * @param[in] trace_callback Callback where the trace data is returned to.
 * @param[in] isa_callback Callback to return ISA lines.
 * @param[in] userdata Userdata passed back to caller via callback.
*/
rocprofiler_att_decoder_status_t rocprofiler_att_decoder_parse_data(
    rocprofiler_att_decoder_se_data_callback_t se_data_callback,
    rocprofiler_att_decoder_trace_callback_t trace_callback,
    rocprofiler_att_decoder_isa_callback_t isa_callback,
    void* userdata
);

/**
 * @brief Returns the description of a rocprofiler_att_decoder_info_t record.
 * @param[in] info The decoder info received
 * @retval null terminated string as description of "info".
*/
const char* rocprofiler_att_decoder_get_info_string(rocprofiler_att_decoder_info_t info);

const char* rocprofiler_att_decoder_get_status_string(rocprofiler_att_decoder_status_t status);

typedef void(*rocprofiler_att_decoder_debug_callback_t)(
    int64_t time,
    const char* type,
    const char* info,
    void* userdata
);

rocprofiler_att_decoder_status_t rocprofiler_att_decoder_dump_data(
    const char* data,
    size_t data_size,
    rocprofiler_att_decoder_debug_callback_t cb,
    void* userdata
);

#ifdef __cplusplus
}
#endif
