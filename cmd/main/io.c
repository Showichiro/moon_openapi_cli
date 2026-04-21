#include <errno.h>
#include <moonbit.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static moonbit_bytes_t make_status_bytes(int status, const uint8_t *data, int32_t len) {
  moonbit_bytes_t out = moonbit_make_bytes(len + 1, 0);
  out[0] = (uint8_t)status;
  if (len > 0 && data != NULL) {
    memcpy(out + 1, data, (size_t)len);
  }
  return out;
}

static moonbit_bytes_t make_status_cstr(int status, const char *message) {
  int32_t len = (int32_t)strlen(message);
  return make_status_bytes(status, (const uint8_t *)message, len);
}

static moonbit_bytes_t make_errno_result(const char *prefix, const char *path) {
  char buffer[1024];
  snprintf(buffer, sizeof(buffer), "%s '%s': %s", prefix, path, strerror(errno));
  return make_status_cstr(1, buffer);
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_apispec_read_file(moonbit_bytes_t path_bytes) {
  const char *path = (const char *)path_bytes;
  FILE *file = fopen(path, "rb");
  if (file == NULL) {
    return make_errno_result("failed to open", path);
  }

  if (fseek(file, 0, SEEK_END) != 0) {
    moonbit_bytes_t result = make_errno_result("failed to seek", path);
    fclose(file);
    return result;
  }
  long size = ftell(file);
  if (size < 0) {
    moonbit_bytes_t result = make_errno_result("failed to tell", path);
    fclose(file);
    return result;
  }
  if (fseek(file, 0, SEEK_SET) != 0) {
    moonbit_bytes_t result = make_errno_result("failed to rewind", path);
    fclose(file);
    return result;
  }

  moonbit_bytes_t out = moonbit_make_bytes((int32_t)size + 1, 0);
  out[0] = 0;
  size_t read_len = fread(out + 1, 1, (size_t)size, file);
  if (read_len != (size_t)size) {
    moonbit_bytes_t result = make_errno_result("failed to read", path);
    fclose(file);
    return result;
  }
  fclose(file);
  return out;
}

MOONBIT_FFI_EXPORT
moonbit_bytes_t moonbit_apispec_read_stdin(void) {
  size_t capacity = 8192;
  size_t len = 0;
  uint8_t *buffer = (uint8_t *)malloc(capacity);
  if (buffer == NULL) {
    return make_status_cstr(1, "failed to allocate stdin buffer");
  }

  while (1) {
    if (len == capacity) {
      capacity *= 2;
      uint8_t *next = (uint8_t *)realloc(buffer, capacity);
      if (next == NULL) {
        free(buffer);
        return make_status_cstr(1, "failed to grow stdin buffer");
      }
      buffer = next;
    }
    size_t n = fread(buffer + len, 1, capacity - len, stdin);
    len += n;
    if (n == 0) {
      if (ferror(stdin)) {
        free(buffer);
        return make_status_cstr(1, "failed to read stdin");
      }
      break;
    }
  }

  moonbit_bytes_t result = make_status_bytes(0, buffer, (int32_t)len);
  free(buffer);
  return result;
}

MOONBIT_FFI_EXPORT
void moonbit_apispec_write_stdout(moonbit_bytes_t output) {
  fwrite(output, 1, Moonbit_array_length(output), stdout);
}

MOONBIT_FFI_EXPORT
void moonbit_apispec_write_stderr(moonbit_bytes_t output) {
  fwrite(output, 1, Moonbit_array_length(output), stderr);
}
