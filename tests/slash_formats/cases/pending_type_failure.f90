program p
implicit none
character(16)::f
f='(i0,/,a)'
write(*,'(a)',advance='no')'KEEP'
write(*,f)1,2
end program
