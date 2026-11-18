program p
implicit none
character(65536)::s
character(16)::f
s=repeat('x',65536)
f='(a,/)'
write(*,'(a)',advance='no')'KEEP'
write(*,f)s
end program
