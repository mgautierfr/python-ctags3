"""
$Id$

This file is part of Python-Ctags.

Python-Ctags is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Python-Ctags is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Python-Ctags.  If not, see <http://www.gnu.org/licenses/>.
"""

cdef extern from "string.h":
    char* strerror(int errnum)

include "stdlib.pxi"
include "readtags.pxi"

cdef create_tagEntry(const tagEntry* const c_entry):
    cdef dict ret = {}
    ret['name'] = c_entry.name
    ret['file'] = c_entry.file
    ret['fileScope'] = c_entry.fileScope
    if c_entry.address.pattern != NULL:
        ret['pattern'] = c_entry.address.pattern
    if c_entry.address.lineNumber:
        ret['lineNumber'] = c_entry.address.lineNumber
    if c_entry.kind != NULL:
        ret['kind'] = c_entry.kind
    for index in range(c_entry.fields.count):
        key = c_entry.fields.list[index].key
        ret[key.decode()] = c_entry.fields.list[index].value
    return ret

cdef class CTags:
    cdef tagFile* file
    cdef tagFileInfo info
    cdef tagEntry c_entry

    def __cinit__(self, filepath):
        self.file = ctagsOpen(filepath, &self.info)
        if not self.file:
            raise OSError(self.info.status.error_number,
                          strerror(self.info.status.error_number),
                          filepath)

    def __dealloc__(self):
        if self.file:
            ctagsClose(self.file)

    def __getitem__(self, key):
        ret = None
        if key == 'format':
            return self.info.file.format
        elif key == 'sort':
            return self.info.file.sort
        else:
            if key == 'author':
                ret = self.info.program.author
            elif key == 'name':
                ret = self.info.program.name
            elif key == 'url':
                ret = self.info.program.url
            elif key == 'version':
                ret = self.info.program.version
            if ret is None:
                raise KeyError(key)
            return ret

    def setSortType(self, tagSortType type):
        success = ctagsSetSortType(self.file, type)
        if not success:
            raise RuntimeError()

    def first(self):
        success = ctagsFirst(self.file, &self.c_entry)
        if not success:
            raise RuntimeError()
        return create_tagEntry(&self.c_entry)

    def find(self, bytes name, int options):
        success = ctagsFind(self.file, &self.c_entry, name, options)
        if not success:
            raise RuntimeError()
        return create_tagEntry(&self.c_entry)

    def findNext(self):
        success = ctagsFindNext(self.file, &self.c_entry)
        if not success:
            raise RuntimeError()
        return create_tagEntry(&self.c_entry)

    def next(self):
        success = ctagsNext(self.file, &self.c_entry)
        if not success:
            raise RuntimeError()
        return create_tagEntry(&self.c_entry)

