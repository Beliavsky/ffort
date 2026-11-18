program main
implicit none
real,target::x(-2:0)
real,pointer::q(:)
q=>x
if(any(lbound(q)/=[-2])) error stop 1
q=>x(-1:0)
if(any(lbound(q)/=[1])) error stop 2
end program
