program main
implicit none
integer,target::a(2)
integer,pointer::p(:)
p=>a
print *,p(1)
end program
