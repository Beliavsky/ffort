! SPDX-License-Identifier: MIT
program test_compact_value_storage
    use fi_ir, only: value_t, component_value_t, ty_integer, ty_derived_base
    implicit none
    type(value_t) :: a,b,c
    type(value_t),allocatable :: values(:),copy(:)
    integer :: stat
    ! The record payload is absent for ordinary values and allocated only for
    ! derived scalars. Intrinsic assignment must preserve independent ownership.
    if(allocated(a%record)) error stop 'unexpected default record allocation'
    a%tag=ty_derived_base+1
    allocate(a%record,stat=stat)
    if(stat/=0) error stop 'record allocation'
    allocate(a%record%components(1),a%record%component_defined(1),stat=stat)
    if(stat/=0) error stop 'component allocation'
    a%record%components(1)=component_value_t(tag=ty_integer,i=17)
    a%record%component_defined=.true.
    b=a
    b%record%components(1)%i=23
    b%record%component_defined=.false.
    if(a%record%components(1)%i/=17.or..not.a%record%component_defined(1)) error stop 'record copy aliases'
    c=b
    deallocate(b%record)
    if(c%record%components(1)%i/=23.or.c%record%component_defined(1)) error stop 'copy lifetime'
    allocate(values(2),copy(2))
    values(1)=a;values(2)=c;copy=values
    values(1)%record%components(1)%i=91
    if(copy(1)%record%components(1)%i/=17) error stop 'array copy aliases'
    values=value_t(tag=ty_integer,i=3)
    if(allocated(values(1)%record).or.allocated(values(2)%record)) error stop 'record payload not released'
    if(values(1)%i/=3.or.copy(2)%record%components(1)%i/=23) error stop 'scalar expansion or retained copy'
    print '(a,i0,a)', 'PASS: compact value ownership; value_t occupies ',storage_size(value_t())/8,' bytes'
end program
