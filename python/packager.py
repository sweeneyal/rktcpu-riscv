import pathlib
import re

def get_vhdl_files(dir, recursive=False):
    directory = pathlib.Path(dir)
    if recursive:
        allVhdlFiles = list(directory.rglob('*.vhd'))
    else:
        allVhdlFiles = list(directory.glob('*.vhd'))
    return allVhdlFiles

def get_entity_declaration(text):
    topPattern = 'entity (.*?) is\n'
    entityName = re.findall(topPattern, text, re.DOTALL)[0]
    pattern    = 'entity {} is.*\n*end entity {};'.format(entityName, entityName)
    return re.findall(pattern, text, re.DOTALL)[0]

header = \
"""library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

library universal;
    use universal.CommonTypes.all;
    use universal.CommonFunctions.all;"""

def package_entities(directory, packageName):
    files = get_vhdl_files(directory)
    entities = list()
    for file in files:
        f = open(file, 'r')
        text = f.read()
        entities.append(get_entity_declaration(text))
    with open(directory + '/pkg/' + packageName + '.vhd', 'w') as pkg:
        pkg.write(header)
        pkg.write('\n\n')
        pkg.write('package {} is\n\n'.format(packageName))
        for entity in entities:
            component = entity.replace('entity', 'component')
            pkg.write(component + '\n\n')
        pkg.write('end package {};'.format(packageName))


package_entities('hdl/rtl/Control', 'ControlEntities')
package_entities('hdl/rtl/DataPath', 'DataPathEntities')