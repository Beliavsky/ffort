program p
implicit none
integer::stat
character(40)::text
character(:),allocatable::a(:,:,:)
text='one two three four'
allocate(character(4)::a(2,1,2))
read(text,*,iostat=stat)a
if(stat/=0.or.a(1,1,1)/='one'.or.a(2,1,1)/='two'.or.a(1,1,2)/='thre'.or.a(2,1,2)/='four')stop 1
print '(a)', "OK"
end program
