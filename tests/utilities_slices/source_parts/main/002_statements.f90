write (*,"(100(a,1x))") ["dog","cat","boy"] .exclude. ["cat "]
write (*,"(100(a,1x))") ["dog","cat","boy"] .exclude. ["dog","cat","boy"]
write (*,"(100(a,1x))") ["dog","cat","boy"] .exclude. char_vec
! words(:,1) = ["cat  ","phone","sing ","big  ","dog  "]
words = ["adj  ","noun ","verb ","adj  ","noun "]
call unique_values(words,words_unique,freq=freq,igroup=igroup) ! ,freq,igroup)
call write_words("words:",words,"(1000(1x,a))")
call write_words("words_unique:",words_unique,"(1000(1x,a))")
print*,"freq =",freq
print*,"igroup =",igroup
print*,"call add_one_var(6,[2,3],iuse)"
call add_one_var(6,[2,3],iuse)
do i=1,size(iuse,1)
   write (*,"(100i6)") iuse(i,:)
end do
