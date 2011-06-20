# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# Author: Emanuel Fonseca
# Email:  emdfonseca<at>gmail<dot>com
# Date:   25 August 2008

import cjson

class Title(dict):
    def __init__(self, title, style=None):
        self['text'] = title
        self.set_style(style)

    def set_style(self, style):
        if style:
            self['style'] = style

class y_legend(Title):
    pass

class x_legend(Title):
    pass

##########################################
# axis classes
class axis(dict):
    def __init__(self, stroke=None, tick_height=None, colour=None, grid_colour=None, steps=None):
        self.set_stroke(stroke)
        self.set_tick_height(tick_height)
        self.set_colour(colour)
        self.set_grid_colour(grid_colour)
        self.set_steps(steps)

    def set_stroke(self, stroke):
        if stroke:
            self['stroke'] = stroke

    def set_tick_height(self, tick_height):
        if tick_height:
            self['tick_height'] = tick_height

    def set_colour(self, colour):
        if colour:
            self['colour'] = colour
    
    def set_grid_colour(self, grid_colour):
        if grid_colour:
            self['grid_colour'] = grid_colour

    def set_steps(self, steps):
        if steps:
            self['steps'] = steps
    
class x_axis(axis):
    def __init__(self, stroke=None, tick_height=None, colour=None, grid_colour=None, labels=None, steps=None):
        axis.__init__(self, stroke, tick_height, colour, grid_colour, steps)
        self.set_labels(labels)
        self['orientation'] = 2

    def set_labels(self, labels):
        if labels:
            self['labels'] = labels

class y_axis(axis):
    def __init__(self, stroke=None, tick_height=None, colour=None, grid_colour=None, offset=None, max=None, min=None, steps=None):
        axis.__init__(self, stroke, tick_height, colour, grid_colour, steps)
        self.set_offset(offset)
        self.set_max(max)
        self.set_min(min)

    def set_offset(self, offset):
        if offset:
            self['offset'] = offset
    
    def set_max(self, max):
        if max:
            self['max'] = max

    def set_min(self, min):
        if min:
            self['min'] = min

##########################################
# open_flash_chart class
class tooltip(dict):
    def __init__(self, shadow=None, stroke=None, colour=None, bg_colour=None, title_style=None, body_style=None):
        self.set_shadow(shadow)
        self.set_stroke(stroke)
        self.set_colour(colour)
        self.set_background(bg_colour)
        self.set_title(title_style)
        self.set_body(body_style)

    def set_shadow(self, shadow):
        if shadow:
            self['shadow'] = shadow
    
    def set_stroke(self, stroke):
        if stroke:
            self['stroke'] = stroke
    
    def set_colour(self, colour):
        if colour:
            self['colour'] = colour
    
    def set_background(self, background):
        if background:
            self['background'] = background
    
    def set_title(self, title):
        if title:
            self['title'] = title
    
    def set_body(self, body):
        if body:
            self['body'] = body

##########################################
# open_flash_chart class
class open_flash_chart(dict):
    def __init__(self, title, style=None):
        self['title'] = Title(title, style)

    def set_x_legend(self, legend):
        self['x_legend'] = x_legend(legend)

    def set_y_legend(self, legend):
        self['y_legend'] = y_legend(legend)

    def set_x_axis(self, stroke=None, tick_height=None, colour=None, grid_colour=None, labels=None, steps=None):
        self['x_axis'] = x_axis(stroke, tick_height, colour, grid_colour, labels, steps)
    
    def set_y_axis(self, stroke=None, tick_height=None, colour=None, grid_colour=None, offset=None, max=None, min=None, steps=None):
        self['y_axis'] = y_axis(stroke, tick_height, colour, grid_colour, offset, max, min, steps)
    
    def set_y_axis_right(self, stroke=None, tick_height=None, colour=None, grid_colour=None, offset=None, max=None, min=None, steps=None):
        self['y_axis_right'] = y_axis(stroke, tick_height, colour, grid_colour, offset, max, min, steps)

    def set_bg_colour(self, colour):
        self['bg_colour'] = colour

    def set_tooltip(self,  shadow=None, stroke=None, colour=None, bg_colour=None, title_style=None, body_style=None):
        self['tooltip'] = tooltip(shadow, stroke, colour, bg_colour, title_style, body_style)

    def add_element(self, element):
        try:
            self['elements'].append(element)
        except:
            self['elements'] = [element]

    def encode(self):
        return cjson.encode(self)

#ofc = open_flash_chart('Example JSON')
#ofc.set_y_legend('Example Y Legend')
#ofc.set_x_legend('Example X Legend')
#ofc.set_x_axis(1, 1, '#ff0000', '#00ff00', ['sun', 'mon', 'tue'])
#ofc.set_x_axis(labels=['sun', 'mon', 'tue'])

#print cjson.encode(ofc)
