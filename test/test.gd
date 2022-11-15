extends SceneTree

func _init():
    var escape = PoolByteArray([0x1B]).get_string_from_ascii()

    _test('Extracting a single small text file', 'res://test/lorem.zip', { 
        'lorem.txt': '705e5a1242c9955ae2651effa14e2f57', 
    })
    _test('Extracting ODS file', 'res://test/test.ods', {
        'settings.xml': '1591265ba416206331f44433ee4055e1',
        'Pictures/100000000000016D000002239004DB26F9D78EC7.png': '96c665a9dd8f31e0c772cee1e5e72479',
        'Pictures/100000000000012C000001907D2704FE2815841F.jpg': 'df71519c2bf258ae0afafeef0e108a39',
        'content.xml': 'e0637cafcf60b89583fdba149e485f33',
        'meta.xml': 'bbf0c6e4fb2911d38b06409008f73630',
        'META-INF/manifest.xml': 'fc5f7c9d59223b1ffdc71b95e8d2abed',
        'styles.xml': '79bc2f11de5c21223000d665dfdbb1c5',
        'mimetype': '0b176652ec360b621a46dfd4268e0c0c',
        'manifest.rdf': 'ea9300f431c910e10f0da4810cd87433',
        'Thumbnails/thumbnail.png': 'ed3d7e2902dddfb950c0130b1cbc4c49',
    })
    _test('Extracting Alice', 'res://test/alice.zip', {
        'alice.txt': '75b098332aa8419a72bf0b78ee73dc42',
    })
    quit()

func _green_text(text):
    var escape = PoolByteArray([0x1B]).get_string_from_ascii()
    var code = "[1;32m"
    return escape + code + text + escape + '[0;0m'

func _red_text(text):
    var escape = PoolByteArray([0x1B]).get_string_from_ascii()
    var code = "[1;31m"
    return escape + code + text + escape + '[0;0m'

func _test(test_name, zip_file, files):
    print('[' + test_name + ']')

    var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
    var loaded = gdunzip.load(zip_file)

    if !loaded:
        print('- Failed loading zip file')
        return false

    var success = true

    for file in files:
        var uncompressed = gdunzip.uncompress(file)
        if !uncompressed:
            print(_red_text('✗') + ' Failed uncompressing ' + file)
            success = false
            continue

        var tmp_file = File.new()
        var tmp_file_name = file.md5_text()
        tmp_file.open('user://' + tmp_file_name, File.WRITE)
        tmp_file.store_buffer(uncompressed)
        tmp_file.close()
        var md5 = tmp_file.get_md5('user://' + file.md5_text())
        Directory.new().remove('user://' + tmp_file_name)

        if md5 != files[file]:
            print(_red_text('✗') + ' Failed uncompressing. MD5 of uncompressed ' + file + ' does not match')
            success = false
            continue

        print(_green_text('✓') +  ' Successfully uncompressed ' + file)

    print()
    return success
