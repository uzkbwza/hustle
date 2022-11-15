extends SceneTree

func _init():
    var gdunzip = load('res://addons/gdunzip/gdunzip.gd').new()
    var loaded = gdunzip.load('res://test/alice.zip')

    if !loaded:
        print('- Failed loading zip file')
        return false

    print('Uncompressing alice.txt 5 times')
    var previous_average = 9355
    var sum_time = 0
    for i in range(0,5):
        var time_before = OS.get_ticks_msec()
        gdunzip.uncompress('alice.txt')
        var total_time = OS.get_ticks_msec() - time_before
        sum_time += total_time
        print('Uncompress time: ' + str(total_time) + 'ms')
        print('----------------------')
    var average_time = sum_time / 5
    print('Average uncompress time: ' + str(average_time) + 'ms')

    print('Speedup: ' + str(float(previous_average) / float(average_time)))
    quit()
