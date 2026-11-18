program main
implicit none
character(:),allocatable::s
integer::v(2),ios
v=[8,9]
s='4'
read(s,*,iostat=ios) v
write(*,'(a)') 'before'
write(*,'(a,i0)') 'MUST NOT LEAK',v(1)
end program
