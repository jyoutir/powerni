import os

def get_project_root():
    """Returns project root folder."""
    return os.path.dirname(os.path.abspath(__file__))

def get_data_path(relative_path):
    """Returns absolute path to data file."""
    return os.path.join(get_project_root(), relative_path)