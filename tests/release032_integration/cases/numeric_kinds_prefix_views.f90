! Synthetic release 0.32 composition fixture; no original utility body.
program main
implicit none
integer(8),target::a(5)
integer(8),pointer::p(:)
real,target::b(4)
real,pointer::r(:)
a=0_8
b=[1.0,2.0,3.0,4.0]
p=>a
r=>b
call fill_i(a,3)
call fill_r(b,2)
where(p>101_8) p=p-100_8
print *,a,r,findloc(p,3_8,kind=8),shape(r)
contains
subroutine fill_i(x,n)
integer,intent(in)::n
integer(8),target,intent(out)::x(n)
x=[101_8,102_8,103_8]
end subroutine
subroutine fill_r(x,n)
integer,intent(in)::n
real,target,intent(inout)::x(n)
x=x*2.0
end subroutine
end program
