program main
implicit none
real,pointer::q(:)
q=>null()
print *,lbound(q)
end program
