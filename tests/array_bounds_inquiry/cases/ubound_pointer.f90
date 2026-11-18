program main
implicit none
real,target::x(-2:0)
real,pointer::q(:)
q=>x
if(any(ubound(q)/=[0])) error stop 1
q=>x(-1:0)
if(any(ubound(q)/=[2])) error stop 2
end program
