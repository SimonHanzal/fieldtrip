function nirs = fieldtrip2homer(data, varargin)

% FIELDTRIP2HOMER converts a continuous raw data structure from FieldTrip format to
% Homer format.
%
% Use as
%   nirs = fieldtrip2homer(data, ...)
% where the input data structure is formatted according to the output of
% FT_PREPROCESSING and the output nirs structure is according to Homer.
%
% Additional options should be specified in key-value pairs and can be
%   'event'        = event structure that corresponds to the data, see FT_READ_EVENT
%
% See https://www.nitrc.org/plugins/mwiki/index.php/homer2:Homer_Input_Files#NIRS_data_file_format
% for a description of the Homer data structure.
%
% See also HOMER2FIELDTRIP, FT_PREPROCESSING, FT_DATATYPE_RAW

% Copyright (C) 2020, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.fieldtriptoolbox.org
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

% ensure that the input is according to the required format
data = ft_checkdata(data, 'datatype', 'raw', 'feedback', true);

% get the optional input arguments
event = ft_getopt(varargin, 'event');

% convert the raw data structure in a low-level representation
hdr = ft_fetch_header(data);
dat = ft_fetch_data(data);

seldat  = startsWith(hdr.chantype, 'nirs');
selstim = strcmp(hdr.chantype, 'stimulus');
selaux  = ~seldat & ~selstim;

if ~isempty(event) && any(selstim)
  ft_error('you can either specify events in a stimulus channel, or as event structure, but not both');
end

nirs.t = data.time{1};
nirs.d = dat(seldat, :)';
nirs.s = dat(selstim, :)';
nirs.aux = dat(selaux, :)';
nirs.CondNames = hdr.label(strcmp(hdr.chantype, 'stimulus'));
nirs.SD = opto2homer(hdr.opto);

if ~isempty(event)
  % convert the event structure into Boolean or integer stimulus channels
  if all(cellfun(@ischar, {event.value}))
    % it has string values, the type is not interesting
    CondNames = unique({event.value});
    boolvec = convert_event(event, 'boolvec', 'valuenames', CondNames, 'endsample', length(nirs.t));
  elseif all(cellfun(@isnumeric, {event.value}))
    % it has numeric values, the type will be a string
    CondNames = unique({event.type});
    boolvec = convert_event(event, 'boolvec', 'typenames', CondNames, 'endsample', length(nirs.t));
  else
    ft_error('this only works when event.type is all numeric or all strings');
  end
  nirs.s = boolvec';
  nirs.CondNames = CondNames;
end
