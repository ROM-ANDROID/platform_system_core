/* Copyright (C) 2002, 2003 Free Software Foundation, Inc.
   This file is part of the GNU C Library.
   Contributed by Hartvig Ekner <hartvige@mips.com>, 2002.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, write to the Free
   Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
   02111-1307 USA.  */

/* void *memset_omips(void *s, int c, size_t n).  */

#include "machine/asm.h"

#ifdef __mips64
#error mips32 code being compiled for mips64!
#endif

#if defined(__MIPSEB__)
#error big-endian is not supported in Broadcom MIPS Android platform
# define SWHI	swl		/* high part is left in big-endian	*/
#else
# define SWHI	swr		/* high part is right in little-endian	*/
#endif

LEAF (memset_omips,0)
	.set	noreorder

	slti	t1, a2, 8		# Less than 8?
	bne	t1, zero, .Llast8
	move	v0, a0			# Setup exit value before too late

	beq	a1, zero, .Lueven	# If zero pattern, no need to extend
	andi	a1, 0xff		# Avoid problems with bogus arguments
	sll	t0, a1, 8
	or	a1, t0
	sll	t0, a1, 16
	or	a1, t0			# a1 is now pattern in full word

.Lueven:
	subu	t0, zero, a0		# Unaligned address?
	andi	t0, 0x3
	beq	t0, zero, .Lchkw
	subu	a2, t0
	SWHI	a1, 0(a0)		# Yes, handle first unaligned part
	addu	a0, t0			# Now both a0 and a2 are updated

.Lchkw:
	andi	t0, a2, 0x7		# Enough left for one loop iteration?
	beq	t0, a2, .Lchkl
	subu	a3, a2, t0
	addu	a3, a0			# a3 is last loop address +1
	move	a2, t0			# a2 is now # of bytes left after loop
.Lloopw:
	addiu	a0, 8			# Handle 2 words pr. iteration
	sw	a1, -8(a0)
	bne	a0, a3, .Lloopw
	sw	a1, -4(a0)

.Lchkl:
	andi	t0, a2, 0x4		# Check if there is at least a full
	beq	t0, zero, .Llast8	#  word remaining after the loop
	subu	a2, t0
	sw	a1, 0(a0)		# Yes...
	addiu	a0, 4

.Llast8:
	blez	a2, .Lexit		# Handle last 8 bytes (if cnt>0)
	addu	a3, a2, a0		# a3 is last address +1
.Llst8l:
	addiu	a0, 1
	bne	a0, a3, .Llst8l
	sb	a1, -1(a0)
.Lexit:
	j	ra			# Bye, bye
	nop

	.set	reorder
END (memset_omips)


