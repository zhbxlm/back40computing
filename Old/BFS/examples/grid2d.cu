/******************************************************************************
 * Copyright 2010 Duane Merrill
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License. 
 * 
 * For more information, see our Google Code project site: 
 * http://code.google.com/p/back40computing/
 * 
 * Thanks!
 ******************************************************************************/

#pragma once

#include <math.h>
#include <time.h>
#include <stdio.h>

#include <test_utils.cu>

/******************************************************************************
 * 2D Grid Graph Construction Routines
 ******************************************************************************/

/**
 * Builds a square 2D grid CSR graph.  Interior nodes have degree 4.  
 * 
 * If src == -1, then it is assigned to the grid-center.  Otherwise it is 
 * verified to be in range of the constructed graph.
 * 
 * Returns 0 on success, 1 on failure.
 */
template<typename VertexId, typename Value, typename SizeT>
int BuildGrid2dGraph(
	VertexId width,
	VertexId &src,
	CsrGraph<VertexId, Value, SizeT> &csr_graph)
{ 
	if (width < 0) {
		fprintf(stderr, "Invalid width: %d", width);
		return -1;
	}
	
	SizeT interior_nodes 		= (width - 2) * (width - 2);
	SizeT edge_nodes 			= (width - 2) * 4;
	SizeT corner_nodes 			= 4;
	
	csr_graph.edges 			= (interior_nodes * 4) + (edge_nodes * 3) + (corner_nodes * 2);
	csr_graph.nodes 			= width * width;
	csr_graph.row_offsets 		= (SizeT*) malloc(sizeof(SizeT) * (csr_graph.nodes + 1));
	csr_graph.column_indices 	= (VertexId*) malloc(sizeof(VertexId) * csr_graph.edges);
	csr_graph.values 			= (Value*) malloc(sizeof(Value) * csr_graph.edges);

	SizeT total = 0;
	for (VertexId j = 0; j < width; j++) {
		for (VertexId k = 0; k < width; k++) {
			
			VertexId me = (j * width) + k;
			csr_graph.row_offsets[me] = total; 

			VertexId neighbor = (j * width) + (k - 1);
			if (k - 1 >= 0) {
				csr_graph.column_indices[total] = neighbor; 
				csr_graph.values[me] = 1;
				total++;
			}

			neighbor = (j * width) + (k + 1);
			if (k + 1 < width) {
				csr_graph.column_indices[total] = neighbor; 
				csr_graph.values[me] = 1;
				total++;
			}
			
			neighbor = ((j - 1) * width) + k;
			if (j - 1 >= 0) {
				csr_graph.column_indices[total] = neighbor; 
				csr_graph.values[me] = 1;
				total++;
			}
			
			neighbor = ((j + 1) * width) + k;
			if (j + 1 < width) {
				csr_graph.column_indices[total] = neighbor; 
				csr_graph.values[me] = 1;
				total++;
			}
		}
	}
	csr_graph.row_offsets[csr_graph.nodes] = total; 	// last offset is always total

	// If unspecified, assign default source.  Otherwise verify source range.
	if (src == -1) {
		VertexId half = width / 2;
		src = half * (width + 1);
	} else if ((src < 0 ) || (src > csr_graph.nodes)) {
		fprintf(stderr, "Invalid src: %d", src);
		csr_graph.Free();
		return -1;
	}
	
	return 0;
}

