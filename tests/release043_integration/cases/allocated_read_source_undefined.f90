program main
implicit none
character(:),allocatable::s
integer::n,ios
allocate(character(4)::s)
read(s,*,iostat=ios) n
end program
