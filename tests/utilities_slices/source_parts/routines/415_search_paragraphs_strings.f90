subroutine search_paragraphs_strings(lines,search_strings,case_sensitive,outu,max_matches,max_lines_print, &
                                     max_lines_search,print_num_matches)
! print paragraph (separated by blank lines) containing search_string
character (len=*), intent(in)           :: lines(:)
character (len=*), intent(in)           :: search_strings(:)
logical          , intent(in), optional :: case_sensitive    ! string matching is case sensitive unless this argument is present and .false.
integer          , intent(in), optional :: outu              ! unit to which output is written
integer          , intent(in), optional :: max_matches       ! maximum # of matching paragraphs to print
integer          , intent(in), optional :: max_lines_print   ! maximum # of lines to print from each paragraph
integer          , intent(in), optional :: max_lines_search  ! maximum # of lines to search within each paragraph
logical          , intent(in), optional :: print_num_matches ! print # of matching paragraphs at end
integer                                 :: outu_,nlines,nmatch,ipar,npar,iblank(size(lines)),i,i1,i2,j,max_lines_print_, &
                                           max_matches_,nlines_search_,isearch
logical                                 :: print_num_matches_
print_num_matches_ = default(.true.,print_num_matches)
max_lines_print_   = default(1000000,max_lines_print)
max_matches_       = default(1000000,max_matches)
nlines_search_     = default(1000000,max_lines_search)
outu_              = default(istdout,outu)
nlines             = size(lines)
npar               = 0
do i=1,nlines
   if (lines(i) == "") then
      npar = npar + 1
      iblank(npar) = i
   end if
end do
nmatch = 0
do_par: do ipar=1,npar
   if (nmatch > max_matches_) exit
   if (ipar == 1) then
      i1 = 1
   else
      i1 = iblank(ipar-1)
   end if
   i2 = iblank(ipar)
   if (all_strings_in_lines(lines(i1:min(i2,i1+1+nlines_search_)),search_strings,case_sensitive=.false.)) then
      nmatch = nmatch + 1
      do j=i1,min(i1+max_lines_print_,i2)
         write (outu_,"(a)") trim(lines(j))
      end do
   end if
end do do_par
if (print_num_matches_) write (outu_,"(/,'#matches = ',i0,' out of ',i0,' for strings = ',100(:,1x,'''',a,''''))")  &
    nmatch,npar,(trim(search_strings(isearch)),isearch=1,size(search_strings))
end subroutine search_paragraphs_strings
!
