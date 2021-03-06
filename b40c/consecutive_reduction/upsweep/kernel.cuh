/******************************************************************************
 * Copyright (c) 2010-2011, Duane Merrill.  All rights reserved.
 * Copyright (c) 2011-2013, NVIDIA CORPORATION.  All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

/******************************************************************************
 * Consecutive reduction upsweep reduction kernel
 ******************************************************************************/

#pragma once

#include <b40c/util/cta_work_distribution.cuh>
#include <b40c/consecutive_reduction/upsweep/cta.cuh>

namespace b40c {
namespace consecutive_reduction {
namespace upsweep {


/**
 * Consecutive reduction upsweep reduction pass
 */
template <typename KernelPolicy>
__device__ __forceinline__ void UpsweepPass(
	typename KernelPolicy::KeyType								*d_in_keys,
	typename KernelPolicy::ValueType							*d_in_values,
	typename KernelPolicy::ValueType 							*d_spine_partials,
	typename KernelPolicy::SizeT								*d_spine_flags,
	typename KernelPolicy::ReductionOp 							reduction_op,
	typename KernelPolicy::EqualityOp							equality_op,
	util::CtaWorkDistribution<typename KernelPolicy::SizeT> 	&work_decomposition,
	typename KernelPolicy::SmemStorage							&smem_storage)
{
	typedef Cta<KernelPolicy> 							Cta;
	typedef typename KernelPolicy::SizeT 				SizeT;
	typedef typename KernelPolicy::SoaScanOperator		SoaScanOperator;

	// CTA processing abstraction
	Cta cta(
		smem_storage,
		d_in_keys,
		d_in_values,
		d_spine_partials,
		d_spine_flags,
		SoaScanOperator(reduction_op),
		equality_op);

	// Determine our threadblock's work range
	util::CtaWorkLimits<SizeT> work_limits;
	work_decomposition.template GetCtaWorkLimits<
		KernelPolicy::LOG_TILE_ELEMENTS,
		KernelPolicy::LOG_SCHEDULE_GRANULARITY>(work_limits);

	// Quit if we're the last threadblock (no need for it in upsweep).
	if (work_limits.last_block) {
		return;
	}

	cta.ProcessWorkRange(work_limits);
}


/**
 * Consecutive reduction upsweep reduction kernel entry point
 */
template <typename KernelPolicy>
__launch_bounds__ (KernelPolicy::THREADS, KernelPolicy::MIN_CTA_OCCUPANCY)
__global__
void Kernel(
	typename KernelPolicy::KeyType								*d_in_keys,
	typename KernelPolicy::ValueType							*d_in_values,
	typename KernelPolicy::ValueType							*d_spine_partials,
	typename KernelPolicy::SizeT								*d_spine_flags,
	typename KernelPolicy::ReductionOp 							reduction_op,
	typename KernelPolicy::EqualityOp							equality_op,
	util::CtaWorkDistribution<typename KernelPolicy::SizeT> 	work_decomposition)
{
	// Shared storage for the kernel
	__shared__ typename KernelPolicy::SmemStorage smem_storage;

	UpsweepPass<KernelPolicy>(
		d_in_keys,
		d_in_values,
		d_spine_partials,
		d_spine_flags,
		reduction_op,
		equality_op,
		work_decomposition,
		smem_storage);
}


} // namespace upsweep
} // namespace consecutive_reduction
} // namespace b40c

