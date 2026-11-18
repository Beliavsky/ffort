program p
implicit none
character(3)::m(2,2),z(0)
logical::flags(0)
m=reshape([' a ','bb ','   ','x x'],[2,2])
print *, len_trim(m),index(m,' '),index(m,' ',back=.true.)
print *, size(adjustl(m),1),size(adjustl(m),2),size(len_trim(m,8),1),size(len_trim(m,8),2), &
size(index(m,'x',kind=8),1),size(index(m,'x',kind=8),2)
print *, size(len_trim(z)),sum(len_trim(z)),size(index(z,'a')),len(adjustl(z))
print *, size(adjustr(z)),kind(len_trim(z,8)),kind(index(z,'b',kind=8))
print *, size(index('abc','b',flags))
end program
