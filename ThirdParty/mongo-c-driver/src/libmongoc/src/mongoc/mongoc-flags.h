/*
 * Copyright 2009-present MongoDB, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <mongoc/mongoc-prelude.h>

#ifndef MONGOC_FLAGS_H
#define MONGOC_FLAGS_H

#include <bson/bson.h>


BSON_BEGIN_DECLS


/**
 * mongoc_remove_flags_t:
 * @MONGOC_REMOVE_NONE: Specify no delete flags.
 * @MONGOC_REMOVE_SINGLE_REMOVE: Only remove the first document matching the
 *    document selector.
 *
 * #mongoc_remove_flags_t are used when performing a remove operation.
 */
typedef enum {
   MONGOC_REMOVE_NONE = 0,
   MONGOC_REMOVE_SINGLE_REMOVE = 1 << 0,
} mongoc_remove_flags_t;


/**
 * mongoc_insert_flags_t:
 * @MONGOC_INSERT_NONE: Specify no insert flags.
 * @MONGOC_INSERT_CONTINUE_ON_ERROR: Continue inserting documents from
 *    the insertion set even if one fails.
 *
 * #mongoc_insert_flags_t are used when performing an insert operation.
 */
typedef enum {
   MONGOC_INSERT_NONE = 0,
   MONGOC_INSERT_CONTINUE_ON_ERROR = 1 << 0,
} mongoc_insert_flags_t;


#define MONGOC_INSERT_NO_VALIDATE (1U << 31)


/**
 * mongoc_query_flags_t:
 * @MONGOC_QUERY_NONE: No query flags supplied.
 * @MONGOC_QUERY_TAILABLE_CURSOR: Cursor will not be closed when the last
 *    data is retrieved. You can resume this cursor later.
 * @MONGOC_QUERY_SECONDARY_OK: Allow query of secondaries in a replica set.
 * @MONGOC_QUERY_OPLOG_REPLAY: Used internally by Mongo.
 * @MONGOC_QUERY_NO_CURSOR_TIMEOUT: The server normally times out idle
 *    cursors after an inactivity period (10 minutes). This prevents that.
 * @MONGOC_QUERY_AWAIT_DATA: Use with %MONGOC_QUERY_TAILABLE_CURSOR. Block
 *    rather than returning no data. After a period, time out.
 * @MONGOC_QUERY_EXHAUST: Stream the data down full blast in multiple
 *    "more" packages. Faster when you are pulling a lot of data and
 *    know you want to pull it all down.
 * @MONGOC_QUERY_PARTIAL: Get partial results from mongos if some shards
 *    are down (instead of throwing an error).
 *
 * #mongoc_query_flags_t is used for querying a Mongo instance.
 */
typedef enum {
   MONGOC_QUERY_NONE = 0,
   MONGOC_QUERY_TAILABLE_CURSOR = 1 << 1,
   MONGOC_QUERY_SECONDARY_OK = 1 << 2,
   MONGOC_QUERY_OPLOG_REPLAY = 1 << 3,
   MONGOC_QUERY_NO_CURSOR_TIMEOUT = 1 << 4,
   MONGOC_QUERY_AWAIT_DATA = 1 << 5,
   MONGOC_QUERY_EXHAUST = 1 << 6,
   MONGOC_QUERY_PARTIAL = 1 << 7,
} mongoc_query_flags_t;


/**
 * mongoc_update_flags_t:
 * @MONGOC_UPDATE_NONE: No update flags specified.
 * @MONGOC_UPDATE_UPSERT: Perform an upsert.
 * @MONGOC_UPDATE_MULTI_UPDATE: Continue updating after first match.
 *
 * #mongoc_update_flags_t is used when updating documents found in Mongo.
 */
typedef enum {
   MONGOC_UPDATE_NONE = 0,
   MONGOC_UPDATE_UPSERT = 1 << 0,
   MONGOC_UPDATE_MULTI_UPDATE = 1 << 1,
} mongoc_update_flags_t;


#define MONGOC_UPDATE_NO_VALIDATE (1U << 31)

BSON_END_DECLS


#endif /* MONGOC_FLAGS_H */
