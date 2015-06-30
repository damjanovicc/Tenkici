
#include "tools.h"
#include "bitmap.h"

#define TEST_MAP_OFFSET ( ( 60 / 2 - 13 ) * 80 + 80 / 2 - 13 )

color_t		color_pallete[ 256 ];
map_entry_t	map[ NUM_MAP_ENTRIES ];
int			num_colors;

void colors_to_mem( FILE * f, unsigned long addr )
{
	unsigned int i;

	for( i = 0; i < 256; i++ ) {
		fprintf( f, "\t\t%lu =>\tx\"", addr );

		if( i < num_colors ) {
            fprintf( f, "00%.2X%.2X%.2X", color_pallete[ i ].b, color_pallete[ i ].g, color_pallete[ i ].r );
		} else {
			fprintf( f, "00000000" );
		}

		if( i < num_colors ) {
			fprintf( f, "\", -- R: %d G: %d B: %d\n", color_pallete[ i ].r, color_pallete[ i ].g, color_pallete[ i ].b );
		} else {
			fprintf( f, "\", -- Unused\n" );
		}

		addr++;
	}
}

char * color_to_string( unsigned char r, unsigned char g, unsigned char b )
{
	static char		str[ 3 ];
	unsigned int	i;
	unsigned int	mask;
	unsigned char	bit;
	unsigned char	found;

	memset( str, '?', 2 );

	found = 0;

	for( i = 0; i < num_colors; i++ ) {
		if( color_pallete[ i ].r == r && color_pallete[ i ].g == g && color_pallete[ i ].b == b ) {
            sprintf( str, "%.2X", i );
			found = 1;
			break;
		}
	}

	// Color is not in pallete but there's still free space, so add it
	if( !found && num_colors < 256 ) {
		color_pallete[ num_colors ].r = r;
		color_pallete[ num_colors ].g = g;
		color_pallete[ num_colors ].b = b;

        sprintf( str, "%.2X", num_colors );

		num_colors++;
	} else {
		if( !found ) {
			printf( "Cannot add color: %d %d %d, pallete is full!\n", r, g, b );
		}
	}

	str[ 2 ] = '\0';

	return str;
}

void image_to_mem( FILE * f, unsigned long addr, unsigned char * img, unsigned char type, char * comment )
{
	unsigned char n;
	unsigned char i;
	unsigned char k;
	unsigned char pixel;

	n = ( type == IMG_8x8 ) ? 8 : 16;

	img += ( n * n - 1 ) * 3;

	for( i = 0; i < n; i++ ) {
		img -= ( n - 1 ) * 3;

		for( k = 0; k < n / 4; k++ ) {
			fprintf( f, "\t\t%lu =>\tx\"", addr );

			// 4 color pallete indexes
			for( pixel = 0; pixel < 4; pixel++ ) {
				fprintf( f, color_to_string( img[ 2 ], img[ 1 ], img[ 0 ] ) );
				img += 3;
			}

			if( !i && !k ) {
				fprintf( f, "\", -- %s\n", comment );
			} else {
				fprintf( f, "\",\n" );
			}

			addr++;
		}

		img -= ( n + 1 ) * 3;
	}
}

void process_images( const char * dir, FILE * mem_file, FILE * def_file, unsigned long * base_addr, unsigned char type )
{
	char				search_dir[ MAX_PATH ];
	char				file_path[ MAX_PATH ];
	char				def_name[ 128 ];
	unsigned char *		img;
	WIN32_FIND_DATA		find_data;
	HANDLE				find;

	sprintf( search_dir, ( type == IMG_8x8 ) ? "%s\\8x8\\*.bmp" : "%s\\16x16\\*.bmp", dir );

	if( !( find = FindFirstFile( search_dir, &find_data ) ) ) {
		printf( "FindFirstFile failed.\n" );
		return;
	}

	do {
		if( !( find_data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY ) ) {
			sprintf( file_path, ( type == IMG_8x8 ) ? "%s\\8x8\\%s" : "%s\\16x16\\%s", dir, find_data.cFileName );

			if( !( img = load_bitmap( file_path ) ) ) {
				printf( "Failed to open: %s\n", file_path );
				continue;
			}

			sprintf( def_name, ( type == IMG_8x8 ) ? "IMG_8x8_%s" : "IMG_16x16_%s", find_data.cFileName );

			// Remove .bmp extension
			def_name[ strlen( def_name ) - 4 ] = '\0';

			fprintf( def_file, "#define %s\t\t\t0x%.4X\n", def_name, *base_addr );

			image_to_mem( mem_file, *base_addr, img, type, def_name );

			// Each image row gets split into 4 byte parts in order to fit memory size.
			*base_addr += ( type == IMG_8x8 ) ? 8 * 2 : 16 * 4;

			free( img );
		}
	} while( FindNextFile( find, &find_data ) );

	FindClose( find );
}

void create_test_map( )
{
	unsigned int    x;
	unsigned int	y;
    unsigned char   tmp;
    FILE *          f;

	for( x = 0; x < NUM_MAP_ENTRIES; x++ ) {
		map[ x ].z = 0;
		map[ x ].rot = 0;
		map[ x ].ptr = 0x0100; // Blank
	}

    if( !( f = fopen( "map2.map", "rb" ) ) ) {
        printf( "Couldn't open 'map2.map' file!\n" );
        return;
    }

    for( y = 0; y < 26; y++ ) {
		for( x = 0; x < 26; x++ ) {
			fread( &tmp, sizeof( unsigned char ), 1, f );

			map[ TEST_MAP_OFFSET + y * 80 + x ].rot = 0;

			if( tmp == 0x31 ) {	// Brick
				map[ TEST_MAP_OFFSET + y * 80 + x ].ptr = 0x0110;
				map[ TEST_MAP_OFFSET + y * 80 + x ].z = 0;
			} else if( tmp == 0x34 || tmp == 0x32 ) {			// Grass
				map[ TEST_MAP_OFFSET + y * 80 + x ].ptr = 0x0130;
				map[ TEST_MAP_OFFSET + y * 80 + x ].z = 0;
			} else if( tmp == 0x35 ) {			// Iron
				map[ TEST_MAP_OFFSET + y * 80 + x ].ptr = 0x0150;
				map[ TEST_MAP_OFFSET + y * 80 + x ].z = 0;
			} else {							// Null object
				map[ TEST_MAP_OFFSET + y * 80 + x ].ptr = 0x0170;
				map[ TEST_MAP_OFFSET + y * 80 + x ].z = 0;
			}
		}
    }
    
    fclose( f );
}

void map_to_mem( FILE * mem_file, FILE * def_file, unsigned long * base_addr )
{
	unsigned int i;

	fprintf( def_file, "#define MAP_BASE_ADDRESS\t\t\t0x%.4X", *base_addr );

	for( i = 0; i < NUM_MAP_ENTRIES; i++ ) {
        fprintf( mem_file, "\t\t%lu =>\tx\"%.2X%.2X%.4X\", -- z: %d rot: %d ptr: %d\n", *base_addr,
                                                                                        map[ i ].z,
                                                                                        map[ i ].rot,
                                                                                        map[ i ].ptr,
                                                                                        map[ i ].z,
                                                                                        map[ i ].rot,
                                                                                        map[ i ].ptr );

		*base_addr += 1;
	}
}