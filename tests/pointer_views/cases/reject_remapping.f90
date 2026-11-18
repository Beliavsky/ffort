program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
p(0:)=>a
end program
