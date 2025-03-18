from pathlib import Path

def print_tree(directory, prefix=""):
    entries = list(directory.iterdir())
    pointers = ["├── "] * (len(entries) - 1) + ["└── "]
    
    for pointer, entry in zip(pointers, entries):
        print(prefix + pointer + entry.name)
        if entry.is_dir():
            extension = "│   " if pointer == "├── " else "    "
            print_tree(entry, prefix + extension)

# Thay 'your_project_path' bằng đường dẫn thư mục
print_tree(Path("./src/pipeline/models"))
