program p
implicit none

print *,len(max(repeat('x',65536),'a')),len_trim(max(repeat('x',65536),'a'))
end program
