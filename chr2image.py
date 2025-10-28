# requires: pip install Pillow
import sys
from PIL import Image

IMAGE_WIDTH = 128
IMAGE_HEIGHT = 128
CELL_WIDTH = 8
CELL_HEIGHT = 8
CELL_ROWS = IMAGE_WIDTH // CELL_WIDTH
CELL_COLS = IMAGE_HEIGHT // CELL_HEIGHT
BYTES_PER_TILE = 16


class CHR2Image:
    def __init__(self, src_filename):
        with open(src_filename, 'rb') as handle:
            self.data = handle.read()

        if self.data[0:4] != b'NES\x1A':
            raise Exception('Invalid cartridge')

        self.prg_num = self.data[4]
        self.chr_num = self.data[5]

    def _encode_tile(self, image, chr, cell_x, cell_y):
        """
        planar to chunky conversion of a tile
        """
        base = (cell_y * CELL_COLS + cell_x) * BYTES_PER_TILE
        for y in range(0, CELL_HEIGHT):
            for x in range(0, CELL_WIDTH):
                pixel_x = cell_x * CELL_WIDTH + x
                pixel_y = cell_y * CELL_HEIGHT + y
                offset0 = base + y
                bit0 = (chr[offset0] >> (7 - x)) & 0x01
                offset1 = base + y + 8
                bit1 = (chr[offset1] >> (7 - x)) & 0x01
                image.putpixel((pixel_x, pixel_y), (bit1 << 1) | bit0)

    def _encode_image(self, filename, chr_table):
        table = Image.new('P', (128, 128))
        table.putpalette((0, 0, 0, 255, 0, 0, 0, 255, 0, 0, 0, 255))
        for cell_y in range(0, IMAGE_HEIGHT // CELL_HEIGHT):
            for cell_x in range(0, IMAGE_WIDTH // CELL_WIDTH):
                self._encode_tile(table, chr_table, cell_x, cell_y)
        table.save(filename)

    def extract(self, dst_filenames):
        offset = 16 + self.prg_num * 0x4000
        index = 0
        for chr in range(0, self.chr_num):
            offset += chr * 0x2000
            chr_table0 = self.data[offset:offset + 0x1000]
            chr_table1 = self.data[offset+0x1000:offset + 0x2000]
            self._encode_image(sys.argv[index+2], chr_table0)
            index += 1
            self._encode_image(sys.argv[index+2], chr_table1)
            index += 1


if __name__ == '__main__':
    if len(sys.argv) < 2:
        raise Exception('path to the rom file required!')
    chr2image = CHR2Image(sys.argv[1])
    print('Detected {0} prg 16k banks and {1} chr 8k banks'.format(
        chr2image.prg_num, chr2image.chr_num))
    if len(sys.argv) < (chr2image.chr_num * 2) + 2:
        raise Exception('not enough image output files specified!')
    chr2image.extract(sys.argv[2:])
