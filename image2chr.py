# requires: pip install Pillow
import sys
from PIL import Image

IMAGE_WIDTH = 128
IMAGE_HEIGHT = 128
CELL_WIDTH = 8
CELL_HEIGHT = 8
CELL_ROWS = IMAGE_WIDTH / CELL_WIDTH
CELL_COLS = IMAGE_HEIGHT / CELL_HEIGHT
BYTES_PER_TILE = 16


class Image2CHR:

    def __init__(self, filename):
        self.image = Image.open(filename)
        self.width, self.height = self.image.size
        if self.width != IMAGE_WIDTH or self.height != IMAGE_HEIGHT:
            raise Exception('invalid image size, must be 128x128')

    def _encode_tile(self, cell_x, cell_y):
        plane0 = []
        plane1 = []
        for y in range(0, CELL_HEIGHT):
            byte0 = 0
            byte1 = 0
            for x in range(0, CELL_WIDTH):
                # retrieve the pixel x and y based on the tile and the current tile-pixel
                pixel_x = cell_x * CELL_WIDTH + x
                pixel_y = cell_y * CELL_HEIGHT + y
                pixel_value = self.image.getpixel((pixel_x, pixel_y))
                if not 0 <= pixel_value <= 3:
                    pixel_value = 3
                    print('warning, found a pixel with color not in range 0-3')
                byte0 |= (pixel_value & 0x01) << (7 - x)
                byte1 |= (pixel_value >> 1) << (7 - x)
            plane0.append(byte0)
            plane1.append(byte1)
        return plane0, plane1

    def encode_tiles(self):
        data = bytearray(0)
        for cell_y in range(0, IMAGE_HEIGHT // CELL_HEIGHT):
            for cell_x in range(0, IMAGE_WIDTH // CELL_WIDTH):
                plane0, plane1 = self._encode_tile(cell_x, cell_y)
                for byte in plane0 + plane1:
                    data += bytes((byte,))

        return data


if __name__ == '__main__':
    if len(sys.argv) < 3:
        raise Exception('paths to the image file and output required!')
    image2chr = Image2CHR(sys.argv[1])
    with open(sys.argv[2], 'wb') as handle:
        handle.write(image2chr.encode_tiles())
