/*
    instance.c -- CLOS interface.
*/
/*
    Copyright (c) 1990, Giuseppe Attardi.
    Copyright (c) 2001, Juan Jose Garcia Ripoll.

    ECL is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    See file '../Copyright' for full details.
*/

#include "ecl.h"

cl_object
ecl_allocate_instance(cl_object clas, int size)
{
	cl_object x = cl_alloc_instance(size);
	int i;
	CLASS_OF(x) = clas;
	for (i = 0;  i < size;  i++)
		x->instance.slots[i] = ECL_UNBOUND;
	return(x);
}

cl_object
si_allocate_raw_instance(cl_object orig, cl_object clas, cl_object size)
{
	cl_object output = ecl_allocate_instance(clas, fixnnint(size));
	if (orig == Cnil) {
		orig = output;
	} else {
		orig->instance.clas = clas;
		orig->instance.length = output->instance.length;
		orig->instance.slots = output->instance.slots;
	}
	@(return orig)
}

cl_object
si_instance_sig(cl_object x)
{
	@(return x->instance.sig);
}

cl_object
si_instance_sig_set(cl_object x)
{
	@(return (x->instance.sig = CLASS_SLOTS(CLASS_OF(x))));
}

cl_object
si_instance_class(cl_object x)
{
	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	@(return CLASS_OF(x))
}

cl_object
si_instance_class_set(cl_object x, cl_object y)
{
	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (type_of(y) != t_instance)
		FEwrong_type_argument(@'ext::instance', y);
	CLASS_OF(x) = y;
	@(return x)
}

cl_object
instance_ref(cl_object x, int i)
{
	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (i >= x->instance.length || i < 0)
	        FEerror("~S is an illegal slot index1.",1,i);
	return(x->instance.slots[i]);
}

cl_object
si_instance_ref(cl_object x, cl_object index)
{
	cl_fixnum i;

	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (!FIXNUMP(index) ||
	    (i = fix(index)) < 0 || i >= x->instance.length)
		FEerror("~S is an illegal slot index.", 1, index);
	@(return x->instance.slots[i])
}

cl_object
si_instance_ref_safe(cl_object x, cl_object index)
{
	cl_fixnum i;

	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (!FIXNUMP(index) ||
	    (i = fix(index)) < 0 || i >= x->instance.length)
		FEerror("~S is an illegal slot index.", 1, index);
	x = x->instance.slots[i];
	if (x == ECL_UNBOUND)
		FEerror("Slot index ~S unbound", 1, index);
	@(return x)
}

cl_object
instance_set(cl_object x, int i, cl_object v)
{
        if (type_of(x) != t_instance)
                FEwrong_type_argument(@'ext::instance', x);
	if (i >= x->instance.length || i < 0)
	        FEerror("~S is an illegal slot index2.", 1, i);
	x->instance.slots[i] = v;
	return(v);
}

cl_object
si_instance_set(cl_object x, cl_object index, cl_object value)
{
	cl_fixnum i;

	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (!FIXNUMP(index) ||
	    (i = fix(index)) >= x->instance.length || i < 0)
		FEerror("~S is an illegal slot index.", 1, index);
	x->instance.slots[i] = value;
	@(return value)
}

cl_object
si_instancep(cl_object x)
{
	@(return ((type_of(x) == t_instance) ? Ct : Cnil))
}

cl_object
si_unbound()
{
	/* Returns an object that cannot be read or written and which
	   is used to represent an unitialized slot */
	@(return ECL_UNBOUND)
}

cl_object
si_sl_boundp(cl_object x)
{
	@(return ((x == ECL_UNBOUND) ? Cnil : Ct))
}

cl_object
si_sl_makunbound(cl_object x, cl_object index)
{
	cl_fixnum i;

	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	if (!FIXNUMP(index) ||
	    (i = fix(index)) >= x->instance.length || i < 0)
		FEerror("~S is an illegal slot index.", 1, index);
	x->instance.slots[i] = ECL_UNBOUND;
	@(return x)
}

cl_object
si_copy_instance(cl_object x)
{
	cl_object y;

	if (type_of(x) != t_instance)
		FEwrong_type_argument(@'ext::instance', x);
	y = ecl_allocate_instance(x->instance.clas, x->instance.length);
	y->instance.sig = x->instance.sig;
	memcpy(y->instance.slots, x->instance.slots,
	       x->instance.length * sizeof(cl_object));
	@(return y)
}

@(defun find-class (name &optional (errorp Ct) env)
	cl_object class;
@
	class = gethash_safe(name, SYM_VAL(@'si::*class-name-hash-table*'), Cnil);
	if (class == Cnil) {
		if (!Null(errorp))
			FEerror("No class named ~S.", 1, name);
	}
	@(return class)
@)
