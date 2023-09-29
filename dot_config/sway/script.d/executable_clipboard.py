#################################################
##
#### Clipboard Manager
##
#################################################
import argparse
import datetime
import hashlib
import json
import os
import sqlite3
import sys

table_schema = """CREATE TABLE IF NOT EXISTS clipboard (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP UNIQUE,
    type TEXT NOT NULL,
    content TEXT UNIQUE,
    image_path TEXT UNIQUE,
    image_hash TEXT UNIQUE
)"""


class ClipboardManager:
    def __init__(self, history_dir, database_path):
        self.history_dir = history_dir
        self.database_path = database_path

        if not os.path.exists(self.history_dir):
            os.makedirs(self.history_dir)
        self.db_query_executor(table_schema)

    def db_query_executor(self, *args):
        connection = sqlite3.connect(self.database_path)
        cursor = connection.cursor()
        cursor.execute(*args)
        connection.commit()
        entries = cursor.fetchall()
        connection.close()
        return entries

    def read_entries(self, limit=10):
        return self.db_query_executor("SELECT * FROM clipboard ORDER BY date DESC LIMIT ?", (limit,))

    def search_entry(self, mode, *args):
        if mode == 'id':
            return self.db_query_executor("SELECT * FROM clipboard WHERE id=?", args)
        elif mode == 'content':
            return self.db_query_executor("SELECT * FROM clipboard WHERE content=?", args)
        elif mode == 'image_hash':
            return self.db_query_executor("SELECT * FROM clipboard WHERE image_hash=?", args)

    def write_entry(self, entry):
        if entry == b'':
            pass
        elif entry.startswith(b'\x89PNG'):
            check_entry = self.search_entry('image_hash', hashlib.md5(entry).hexdigest())
            if not check_entry:
                image_path = os.path.join(self.history_dir, "images")
                image_file = os.path.join(image_path, f"{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}.png")
                if not os.path.exists(image_path):
                    os.makedirs(image_path)
                with open(image_file, 'wb') as f:
                    f.write(entry)
                self.db_query_executor("INSERT INTO clipboard (type, image_path, image_hash) VALUES ('image', ?, ?)",
                                       (image_file, hashlib.md5(entry).hexdigest()))
            else:
                last_entry_id = self.db_query_executor("SELECT * FROM clipboard WHERE image_hash=?", (check_entry[0][5],))
                self.db_query_executor("UPDATE clipboard SET date=CURRENT_TIMESTAMP WHERE id=?", (last_entry_id[0][0],))
        else:
            check_entry = self.search_entry('content', entry)
            if not check_entry:
                self.db_query_executor("INSERT INTO clipboard (type, content) VALUES ('text', ?)", (entry,))
            else:
                last_entry_id = self.db_query_executor("SELECT * FROM clipboard WHERE content=?", (check_entry[0][3],))
                self.db_query_executor("UPDATE clipboard SET date=CURRENT_TIMESTAMP WHERE id=?", (last_entry_id[0][0],))


def main():
    parser = argparse.ArgumentParser(description='Clipboard Manager')
    parser.add_argument('-r', '--read', metavar='x', nargs='?', type=int, const=25, help='read the last x entries')
    parser.add_argument('-w', '--write', action='store_true', help='write data from stdin')
    parser.add_argument('-s', '--search', metavar='id', type=int, help='search and display entry by ID')
    parser.add_argument('--json', action='store_true', help='return data in JSON format')
    parser.add_argument('--shell', action='store_true', help='get data from shell')
    parser.add_argument('--count', action='store_true', help='return number of entries')
    args = parser.parse_args()

    history_dir = os.path.expanduser('~/.cache/clipboard_history')
    db_path = os.path.join(history_dir, 'clipboard.db')
    clipboard_manager = ClipboardManager(history_dir, db_path)

    if args.read:
        entries = clipboard_manager.read_entries(args.read)
        if args.json:
            entries_json = json.dumps(entries, default=str)
            print(entries_json)
        elif args.count:
            print(clipboard_manager.db_query_executor("SELECT COUNT(*) FROM clipboard")[0][0])
        else:
            for entry in entries:
                if entry[2] == 'image':
                    print(f"{str(entry[0]).zfill(4)}: {entry[2]} --- {entry[4]}")
                else:
                    print(f"{str(entry[0]).zfill(4)}: {entry[2]} --- {repr(entry[3].decode())}")
    elif args.write:
        if args.shell:
            data = sys.stdin.buffer.read()[0:-1]
        else:
            data = sys.stdin.buffer.read()
        clipboard_manager.write_entry(data)
    elif args.search:
        entry = clipboard_manager.search_entry('id', args.search)
        if entry:
            if entry[0][2] == 'image':
                with open(entry[0][4], 'rb') as f:
                    sys.stdout.buffer.write(f.read())
            else:
                formatted_data = entry[0][3].decode()
                sys.stdout.buffer.write(formatted_data.encode())
        else:
            print("Entry not found")


if __name__ == '__main__':
    main()
