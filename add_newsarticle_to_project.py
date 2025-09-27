#!/usr/bin/env python3
import os
import uuid
import re

def generate_uuid():
    """Generate a UUID in the format used by Xcode"""
    return str(uuid.uuid4()).replace('-', '').upper()[:24]

def add_newsarticle_files():
    project_path = "/Users/hexa/Desktop/latest-nifty/iOS-Trading-App/iOS-Trading-App.xcodeproj/project.pbxproj"

    # Files to add
    files_to_add = [
        "NewsArticle.swift",
        "NewsArticle+CoreDataProperties.swift"
    ]

    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()

    # Generate UUIDs for each file
    file_refs = {}
    build_files = {}

    for file_name in files_to_add:
        file_refs[file_name] = generate_uuid()
        build_files[file_name] = generate_uuid()

    # Add PBXBuildFile entries
    build_file_section = "/* Begin PBXBuildFile section */"
    build_file_entries = []

    for file_name in files_to_add:
        build_file_entry = f"\t\t{build_files[file_name]} /* {file_name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file_name]} /* {file_name} */; }};"
        build_file_entries.append(build_file_entry)

    # Find the end of PBXBuildFile section and add our entries
    build_file_end = content.find("/* End PBXBuildFile section */")
    if build_file_end != -1:
        content = content[:build_file_end] + "\n".join(build_file_entries) + "\n\t\t" + content[build_file_end:]

    # Add PBXFileReference entries
    file_ref_section = "/* Begin PBXFileReference section */"
    file_ref_entries = []

    for file_name in files_to_add:
        file_ref_entry = f"\t\t{file_refs[file_name]} /* {file_name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file_name}; sourceTree = \"<group>\"; }};"
        file_ref_entries.append(file_ref_entry)

    # Find the end of PBXFileReference section and add our entries
    file_ref_end = content.find("/* End PBXFileReference section */")
    if file_ref_end != -1:
        content = content[:file_ref_end] + "\n".join(file_ref_entries) + "\n\t\t" + content[file_ref_end:]

    # Add to PBXGroup (main group)
    # Find the main group children array
    group_pattern = r'children = \(\s*([^)]*)\s*\);'
    matches = list(re.finditer(group_pattern, content, re.MULTILINE | re.DOTALL))

    if matches:
        # Use the first group (usually the main group)
        match = matches[0]
        children_content = match.group(1)

        # Add our file references
        new_children = []
        for file_name in files_to_add:
            new_children.append(f"\t\t\t\t{file_refs[file_name]} /* {file_name} */,")

        new_children_str = "\n".join(new_children)
        updated_children = children_content.rstrip() + ",\n" + new_children_str

        content = content[:match.start(1)] + updated_children + content[match.end(1):]

    # Add to PBXSourcesBuildPhase
    sources_pattern = r'(files = \(\s*)(.*?)(\s*\);.*?/\* Sources \*/)'
    sources_match = re.search(sources_pattern, content, re.MULTILINE | re.DOTALL)

    if sources_match:
        files_content = sources_match.group(2)

        # Add our build file references
        new_sources = []
        for file_name in files_to_add:
            new_sources.append(f"\t\t\t\t{build_files[file_name]} /* {file_name} in Sources */,")

        new_sources_str = "\n".join(new_sources)
        updated_sources = files_content.rstrip() + ",\n" + new_sources_str

        content = content[:sources_match.start(2)] + updated_sources + content[sources_match.end(2):]

    # Write the updated project file
    with open(project_path, 'w') as f:
        f.write(content)

    print("Successfully added NewsArticle files to Xcode project:")
    for file_name in files_to_add:
        print(f"  - {file_name}")

if __name__ == "__main__":
    add_newsarticle_files()
