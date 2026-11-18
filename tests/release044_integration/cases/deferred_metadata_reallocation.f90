program p
implicit none
character(:),allocatable::s,fmt
integer::i
fmt='(*(i0,1x))'
print fmt,(kind(s%len),i=1,2)
s='abcdef'
print fmt,(s%len,i=1,2)
s='q'
print fmt,(s%len,i=1,2)
deallocate(s)
print fmt,(kind(s%len),i=1,2)
end program
