program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
p=>a
p(3)=1
end program
