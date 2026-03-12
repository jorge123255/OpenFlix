#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSError.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>

@class SharedAuthResponse, SharedAuthResponseCompanion, SharedCastMember, SharedChannel, SharedChannelDTO, SharedChannelDTOCompanion, SharedChannelGroup, SharedChannelGroupDTO, SharedChannelGroupDTOCompanion, SharedChannelGroupMember, SharedChannelGroupMemberDTO, SharedChannelGroupMemberDTOCompanion, SharedChannelGroupsResponse, SharedChannelGroupsResponseCompanion, SharedChannelNowPlayingDTO, SharedChannelNowPlayingDTOCompanion, SharedChannelSortOrder, SharedChannelStreamResponse, SharedChannelStreamResponseCompanion, SharedChannelWithPrograms, SharedChannelsResponse, SharedChannelsResponseCompanion, SharedCollectionDTO, SharedCollectionDTOCompanion, SharedCollectionsContainer, SharedCollectionsContainerCompanion, SharedCollectionsResponse, SharedCollectionsResponseCompanion, SharedCommercial, SharedCommercialDTO, SharedCommercialDTOCompanion, SharedCountryDTO, SharedCountryDTOCompanion, SharedDirectorDTO, SharedDirectorDTOCompanion, SharedDiscoveredServer, SharedDiscoveredServerCompanion, SharedDiscoveryResponse, SharedDiscoveryResponseCompanion, SharedEPGSource, SharedEPGSourceDTO, SharedEPGSourceDTOCompanion, SharedEPGSourceType, SharedEPGSourceTypeCompanion, SharedEPGSourcesResponse, SharedEPGSourcesResponseCompanion, SharedGenreDTO, SharedGenreDTOCompanion, SharedGuideResponse, SharedGuideResponseCompanion, SharedHomeUserDTO, SharedHomeUserDTOCompanion, SharedHomeUsersResponse, SharedHomeUsersResponseCompanion, SharedHub, SharedHubDTO, SharedHubDTOCompanion, SharedHubsContainer, SharedHubsContainerCompanion, SharedHubsResponse, SharedHubsResponseCompanion, SharedKoin_coreBeanDefinition<T>, SharedKoin_coreCallbacks<T>, SharedKoin_coreExtensionManager, SharedKoin_coreInstanceFactory<T>, SharedKoin_coreInstanceFactoryCompanion, SharedKoin_coreInstanceRegistry, SharedKoin_coreKind, SharedKoin_coreKoin, SharedKoin_coreKoinApplication, SharedKoin_coreKoinApplicationCompanion, SharedKoin_coreKoinDefinition<R>, SharedKoin_coreLevel, SharedKoin_coreLockable, SharedKoin_coreLogger, SharedKoin_coreModule, SharedKoin_coreParametersHolder, SharedKoin_corePropertyRegistry, SharedKoin_coreResolutionContext, SharedKoin_coreScope, SharedKoin_coreScopeDSL, SharedKoin_coreScopeRegistry, SharedKoin_coreScopeRegistryCompanion, SharedKoin_coreSingleInstanceFactory<T>, SharedKotlinArray<T>, SharedKotlinEnum<E>, SharedKotlinEnumCompanion, SharedKotlinException, SharedKotlinIllegalStateException, SharedKotlinLazyThreadSafetyMode, SharedKotlinNothing, SharedKotlinPair<__covariant A, __covariant B>, SharedKotlinRuntimeException, SharedKotlinThrowable, SharedKotlinx_serialization_coreSerialKind, SharedKotlinx_serialization_coreSerializersModule, SharedKtor_httpHttpMethod, SharedKtor_httpHttpMethodCompanion, SharedLeaguesResponse, SharedLeaguesResponseCompanion, SharedLibrarySection, SharedLibrarySectionDTO, SharedLibrarySectionDTOCompanion, SharedLibrarySectionType, SharedLibrarySectionTypeCompanion, SharedLibrarySectionsContainer, SharedLibrarySectionsContainerCompanion, SharedLibrarySectionsResponse, SharedLibrarySectionsResponseCompanion, SharedM3USource, SharedM3USourceDTO, SharedM3USourceDTOCompanion, SharedM3USourcesResponse, SharedM3USourcesResponseCompanion, SharedMediaCollection, SharedMediaContainer, SharedMediaContainerCompanion, SharedMediaContainerResponse, SharedMediaContainerResponseCompanion, SharedMediaItem, SharedMediaItemDTO, SharedMediaItemDTOCompanion, SharedMediaPart, SharedMediaPartDTO, SharedMediaPartDTOCompanion, SharedMediaStream, SharedMediaType, SharedMediaTypeCompanion, SharedMediaVersion, SharedMediaVersionDTO, SharedMediaVersionDTOCompanion, SharedNetworkError, SharedNetworkErrorDecodingError, SharedNetworkErrorInvalidURL, SharedNetworkErrorNetworkUnavailable, SharedNetworkErrorNoData, SharedNetworkErrorNotFound, SharedNetworkErrorRateLimited, SharedNetworkErrorServerError, SharedNetworkErrorTimeout, SharedNetworkErrorUnauthorized, SharedNetworkErrorUnknown, SharedNowPlayingResponse, SharedNowPlayingResponseCompanion, SharedOnLaterProgram, SharedOnLaterProgramDTO, SharedOnLaterProgramDTOCompanion, SharedOnLaterResponse, SharedOnLaterResponseCompanion, SharedOnLaterStats, SharedOnLaterStatsResponseDTO, SharedOnLaterStatsResponseDTOCompanion, SharedOpenFlixApi, SharedPlaybackURLResponse, SharedPlaybackURLResponseCompanion, SharedPlaylist, SharedPlaylistDTO, SharedPlaylistDTOCompanion, SharedPlaylistItem, SharedPlaylistItemDTO, SharedPlaylistItemDTOCompanion, SharedPlaylistItemsResponse, SharedPlaylistItemsResponseCompanion, SharedPlaylistsContainer, SharedPlaylistsContainerCompanion, SharedPlaylistsResponse, SharedPlaylistsResponseCompanion, SharedProfile, SharedProfileDTO, SharedProfileDTOCompanion, SharedProgram, SharedProgramDTO, SharedProgramDTOCompanion, SharedRecording, SharedRecordingDTO, SharedRecordingDTOCompanion, SharedRecordingStatsResponse, SharedRecordingStatsResponseCompanion, SharedRecordingStatus, SharedRecordingStatusCompanion, SharedRecordingStreamResponse, SharedRecordingStreamResponseCompanion, SharedRecordingsResponse, SharedRecordingsResponseCompanion, SharedRoleDTO, SharedRoleDTOCompanion, SharedScheduledRecordingsResponse, SharedScheduledRecordingsResponseCompanion, SharedSearchContainer, SharedSearchContainerCompanion, SharedSearchHubDTO, SharedSearchHubDTOCompanion, SharedSearchResponse, SharedSearchResponseCompanion, SharedSeriesRule, SharedSeriesRuleDTO, SharedSeriesRuleDTOCompanion, SharedSeriesRulesResponse, SharedSeriesRulesResponseCompanion, SharedServerCapabilities, SharedServerCapabilitiesDTO, SharedServerCapabilitiesDTOCompanion, SharedServerInfo, SharedServerInfoDTO, SharedServerInfoDTOCompanion, SharedStreamDTO, SharedStreamDTOCompanion, SharedStreamType, SharedStreamTypeCompanion, SharedStringOrInt, SharedStringOrIntCompanion, SharedStringOrIntSerializer, SharedSwitchProfileResponse, SharedSwitchProfileResponseCompanion, SharedTeam, SharedTeamDTO, SharedTeamDTOCompanion, SharedTeamPass, SharedTeamPassDTO, SharedTeamPassDTOCompanion, SharedTeamPassesResponse, SharedTeamPassesResponseCompanion, SharedTeamsResponse, SharedTeamsResponseCompanion, SharedTrailerInfo, SharedUser, SharedUserDTO, SharedUserDTOCompanion, SharedWatchlistItem, SharedWatchlistItemDTO, SharedWatchlistItemDTOCompanion, SharedWatchlistResponse, SharedWatchlistResponseCompanion, SharedWriterDTO, SharedWriterDTOCompanion, SharedXtreamSource, SharedXtreamSourceDTO, SharedXtreamSourceDTOCompanion, SharedXtreamSourcesResponse, SharedXtreamSourcesResponseCompanion;

@protocol SharedKoin_coreKoinComponent, SharedKoin_coreKoinExtension, SharedKoin_coreKoinScopeComponent, SharedKoin_coreQualifier, SharedKoin_coreScopeCallback, SharedKotlinAnnotation, SharedKotlinComparable, SharedKotlinIterator, SharedKotlinKAnnotatedElement, SharedKotlinKClass, SharedKotlinKClassifier, SharedKotlinKDeclarationContainer, SharedKotlinLazy, SharedKotlinx_coroutines_coreFlow, SharedKotlinx_coroutines_coreFlowCollector, SharedKotlinx_coroutines_coreSharedFlow, SharedKotlinx_coroutines_coreStateFlow, SharedKotlinx_serialization_coreCompositeDecoder, SharedKotlinx_serialization_coreCompositeEncoder, SharedKotlinx_serialization_coreDecoder, SharedKotlinx_serialization_coreDeserializationStrategy, SharedKotlinx_serialization_coreEncoder, SharedKotlinx_serialization_coreKSerializer, SharedKotlinx_serialization_coreSerialDescriptor, SharedKotlinx_serialization_coreSerializationStrategy, SharedKotlinx_serialization_coreSerializersModuleCollector;

NS_ASSUME_NONNULL_BEGIN
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunknown-warning-option"
#pragma clang diagnostic ignored "-Wincompatible-property-type"
#pragma clang diagnostic ignored "-Wnullability"

#pragma push_macro("_Nullable_result")
#if !__has_feature(nullability_nullable_result)
#undef _Nullable_result
#define _Nullable_result _Nullable
#endif

__attribute__((swift_name("KotlinBase")))
@interface SharedBase : NSObject
- (instancetype)init __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
+ (void)initialize __attribute__((objc_requires_super));
@end

@interface SharedBase (SharedBaseCopying) <NSCopying>
@end

__attribute__((swift_name("KotlinMutableSet")))
@interface SharedMutableSet<ObjectType> : NSMutableSet<ObjectType>
@end

__attribute__((swift_name("KotlinMutableDictionary")))
@interface SharedMutableDictionary<KeyType, ObjectType> : NSMutableDictionary<KeyType, ObjectType>
@end

@interface NSError (NSErrorSharedKotlinException)
@property (readonly) id _Nullable kotlinException;
@end

__attribute__((swift_name("KotlinNumber")))
@interface SharedNumber : NSNumber
- (instancetype)initWithChar:(char)value __attribute__((unavailable));
- (instancetype)initWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
- (instancetype)initWithShort:(short)value __attribute__((unavailable));
- (instancetype)initWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
- (instancetype)initWithInt:(int)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
- (instancetype)initWithLong:(long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
- (instancetype)initWithLongLong:(long long)value __attribute__((unavailable));
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
- (instancetype)initWithFloat:(float)value __attribute__((unavailable));
- (instancetype)initWithDouble:(double)value __attribute__((unavailable));
- (instancetype)initWithBool:(BOOL)value __attribute__((unavailable));
- (instancetype)initWithInteger:(NSInteger)value __attribute__((unavailable));
- (instancetype)initWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
+ (instancetype)numberWithChar:(char)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedChar:(unsigned char)value __attribute__((unavailable));
+ (instancetype)numberWithShort:(short)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedShort:(unsigned short)value __attribute__((unavailable));
+ (instancetype)numberWithInt:(int)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInt:(unsigned int)value __attribute__((unavailable));
+ (instancetype)numberWithLong:(long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLong:(unsigned long)value __attribute__((unavailable));
+ (instancetype)numberWithLongLong:(long long)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value __attribute__((unavailable));
+ (instancetype)numberWithFloat:(float)value __attribute__((unavailable));
+ (instancetype)numberWithDouble:(double)value __attribute__((unavailable));
+ (instancetype)numberWithBool:(BOOL)value __attribute__((unavailable));
+ (instancetype)numberWithInteger:(NSInteger)value __attribute__((unavailable));
+ (instancetype)numberWithUnsignedInteger:(NSUInteger)value __attribute__((unavailable));
@end

__attribute__((swift_name("KotlinByte")))
@interface SharedByte : SharedNumber
- (instancetype)initWithChar:(char)value;
+ (instancetype)numberWithChar:(char)value;
@end

__attribute__((swift_name("KotlinUByte")))
@interface SharedUByte : SharedNumber
- (instancetype)initWithUnsignedChar:(unsigned char)value;
+ (instancetype)numberWithUnsignedChar:(unsigned char)value;
@end

__attribute__((swift_name("KotlinShort")))
@interface SharedShort : SharedNumber
- (instancetype)initWithShort:(short)value;
+ (instancetype)numberWithShort:(short)value;
@end

__attribute__((swift_name("KotlinUShort")))
@interface SharedUShort : SharedNumber
- (instancetype)initWithUnsignedShort:(unsigned short)value;
+ (instancetype)numberWithUnsignedShort:(unsigned short)value;
@end

__attribute__((swift_name("KotlinInt")))
@interface SharedInt : SharedNumber
- (instancetype)initWithInt:(int)value;
+ (instancetype)numberWithInt:(int)value;
@end

__attribute__((swift_name("KotlinUInt")))
@interface SharedUInt : SharedNumber
- (instancetype)initWithUnsignedInt:(unsigned int)value;
+ (instancetype)numberWithUnsignedInt:(unsigned int)value;
@end

__attribute__((swift_name("KotlinLong")))
@interface SharedLong : SharedNumber
- (instancetype)initWithLongLong:(long long)value;
+ (instancetype)numberWithLongLong:(long long)value;
@end

__attribute__((swift_name("KotlinULong")))
@interface SharedULong : SharedNumber
- (instancetype)initWithUnsignedLongLong:(unsigned long long)value;
+ (instancetype)numberWithUnsignedLongLong:(unsigned long long)value;
@end

__attribute__((swift_name("KotlinFloat")))
@interface SharedFloat : SharedNumber
- (instancetype)initWithFloat:(float)value;
+ (instancetype)numberWithFloat:(float)value;
@end

__attribute__((swift_name("KotlinDouble")))
@interface SharedDouble : SharedNumber
- (instancetype)initWithDouble:(double)value;
+ (instancetype)numberWithDouble:(double)value;
@end

__attribute__((swift_name("KotlinBoolean")))
@interface SharedBoolean : SharedNumber
- (instancetype)initWithBool:(BOOL)value;
+ (instancetype)numberWithBool:(BOOL)value;
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DiscoveredServer")))
@interface SharedDiscoveredServer : SharedBase
- (instancetype)initWithName:(NSString *)name version:(NSString *)version machineId:(NSString *)machineId host:(NSString *)host port:(int32_t)port protocol:(NSString *)protocol localAddresses:(NSArray<NSString *> *)localAddresses __attribute__((swift_name("init(name:version:machineId:host:port:protocol:localAddresses:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedDiscoveredServerCompanion *companion __attribute__((swift_name("companion")));
- (SharedDiscoveredServer *)doCopyName:(NSString *)name version:(NSString *)version machineId:(NSString *)machineId host:(NSString *)host port:(int32_t)port protocol:(NSString *)protocol localAddresses:(NSArray<NSString *> *)localAddresses __attribute__((swift_name("doCopy(name:version:machineId:host:port:protocol:localAddresses:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *displayUrl __attribute__((swift_name("displayUrl")));
@property (readonly) NSString *host __attribute__((swift_name("host")));
@property (readonly) NSArray<NSString *> *localAddresses __attribute__((swift_name("localAddresses")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="machineId")
*/
@property (readonly) NSString *machineId __attribute__((swift_name("machineId")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t port __attribute__((swift_name("port")));
@property (readonly) NSString *protocol __attribute__((swift_name("protocol")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@property (readonly) NSString *version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DiscoveredServer.Companion")))
@interface SharedDiscoveredServerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedDiscoveredServerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DiscoveryResponse")))
@interface SharedDiscoveryResponse : SharedBase
- (instancetype)initWithMagic:(NSString *)magic server:(SharedDiscoveredServer * _Nullable)server __attribute__((swift_name("init(magic:server:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedDiscoveryResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedDiscoveryResponse *)doCopyMagic:(NSString *)magic server:(SharedDiscoveredServer * _Nullable)server __attribute__((swift_name("doCopy(magic:server:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *magic __attribute__((swift_name("magic")));
@property (readonly) SharedDiscoveredServer * _Nullable server __attribute__((swift_name("server")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DiscoveryResponse.Companion")))
@interface SharedDiscoveryResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedDiscoveryResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerDiscoveryService")))
@interface SharedServerDiscoveryService : SharedBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)discoverServersTimeoutMs:(int64_t)timeoutMs completionHandler:(void (^)(NSArray<SharedDiscoveredServer *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("discoverServers(timeoutMs:completionHandler:)")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AuthResponse")))
@interface SharedAuthResponse : SharedBase
- (instancetype)initWithToken:(NSString *)token user:(SharedUserDTO *)user expiresAt:(SharedInt * _Nullable)expiresAt __attribute__((swift_name("init(token:user:expiresAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedAuthResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedAuthResponse *)doCopyToken:(NSString *)token user:(SharedUserDTO *)user expiresAt:(SharedInt * _Nullable)expiresAt __attribute__((swift_name("doCopy(token:user:expiresAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable expiresAt __attribute__((swift_name("expiresAt")));
@property (readonly) NSString *token __attribute__((swift_name("token")));
@property (readonly) SharedUserDTO *user __attribute__((swift_name("user")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AuthResponse.Companion")))
@interface SharedAuthResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedAuthResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelDTO")))
@interface SharedChannelDTO : SharedBase
- (instancetype)initWithId:(SharedStringOrInt * _Nullable)id tvgId:(NSString * _Nullable)tvgId number:(SharedInt * _Nullable)number name:(NSString * _Nullable)name title:(NSString * _Nullable)title callsign:(NSString * _Nullable)callsign logo:(NSString * _Nullable)logo thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art sourceId:(SharedStringOrInt * _Nullable)sourceId sourceName:(NSString * _Nullable)sourceName streamUrl:(NSString * _Nullable)streamUrl enabled:(SharedBoolean * _Nullable)enabled hd:(SharedBoolean * _Nullable)hd isFavorite:(SharedBoolean * _Nullable)isFavorite group:(NSString * _Nullable)group category:(NSString * _Nullable)category archiveEnabled:(SharedBoolean * _Nullable)archiveEnabled archiveDays:(SharedInt * _Nullable)archiveDays nowPlaying:(SharedProgramDTO * _Nullable)nowPlaying nextProgram:(SharedProgramDTO * _Nullable)nextProgram __attribute__((swift_name("init(id:tvgId:number:name:title:callsign:logo:thumb:art:sourceId:sourceName:streamUrl:enabled:hd:isFavorite:group:category:archiveEnabled:archiveDays:nowPlaying:nextProgram:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelDTO *)doCopyId:(SharedStringOrInt * _Nullable)id tvgId:(NSString * _Nullable)tvgId number:(SharedInt * _Nullable)number name:(NSString * _Nullable)name title:(NSString * _Nullable)title callsign:(NSString * _Nullable)callsign logo:(NSString * _Nullable)logo thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art sourceId:(SharedStringOrInt * _Nullable)sourceId sourceName:(NSString * _Nullable)sourceName streamUrl:(NSString * _Nullable)streamUrl enabled:(SharedBoolean * _Nullable)enabled hd:(SharedBoolean * _Nullable)hd isFavorite:(SharedBoolean * _Nullable)isFavorite group:(NSString * _Nullable)group category:(NSString * _Nullable)category archiveEnabled:(SharedBoolean * _Nullable)archiveEnabled archiveDays:(SharedInt * _Nullable)archiveDays nowPlaying:(SharedProgramDTO * _Nullable)nowPlaying nextProgram:(SharedProgramDTO * _Nullable)nextProgram __attribute__((swift_name("doCopy(id:tvgId:number:name:title:callsign:logo:thumb:art:sourceId:sourceName:streamUrl:enabled:hd:isFavorite:group:category:archiveEnabled:archiveDays:nowPlaying:nextProgram:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedChannel *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable archiveDays __attribute__((swift_name("archiveDays")));
@property (readonly) SharedBoolean * _Nullable archiveEnabled __attribute__((swift_name("archiveEnabled")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) NSString * _Nullable callsign __attribute__((swift_name("callsign")));
@property (readonly) NSString * _Nullable category __attribute__((swift_name("category")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) NSString *epgId __attribute__((swift_name("epgId")));
@property (readonly) NSString * _Nullable group __attribute__((swift_name("group")));
@property (readonly) SharedBoolean * _Nullable hd __attribute__((swift_name("hd")));
@property (readonly) SharedStringOrInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable isFavorite __attribute__((swift_name("isFavorite")));
@property (readonly) NSString * _Nullable logo __attribute__((swift_name("logo")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) SharedProgramDTO * _Nullable nextProgram __attribute__((swift_name("nextProgram")));
@property (readonly) SharedProgramDTO * _Nullable nowPlaying __attribute__((swift_name("nowPlaying")));
@property (readonly) SharedInt * _Nullable number __attribute__((swift_name("number")));
@property (readonly) NSString *safeId __attribute__((swift_name("safeId")));
@property (readonly) NSString *safeName __attribute__((swift_name("safeName")));
@property (readonly) SharedStringOrInt * _Nullable sourceId __attribute__((swift_name("sourceId")));
@property (readonly) NSString * _Nullable sourceName __attribute__((swift_name("sourceName")));
@property (readonly) NSString * _Nullable streamUrl __attribute__((swift_name("streamUrl")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable tvgId __attribute__((swift_name("tvgId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelDTO.Companion")))
@interface SharedChannelDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupDTO")))
@interface SharedChannelGroupDTO : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name enabled:(SharedBoolean * _Nullable)enabled members:(NSArray<SharedChannelGroupMemberDTO *> * _Nullable)members __attribute__((swift_name("init(id:name:enabled:members:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelGroupDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelGroupDTO *)doCopyId:(int32_t)id name:(NSString *)name enabled:(SharedBoolean * _Nullable)enabled members:(NSArray<SharedChannelGroupMemberDTO *> * _Nullable)members __attribute__((swift_name("doCopy(id:name:enabled:members:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedChannelGroup *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSArray<SharedChannelGroupMemberDTO *> * _Nullable members __attribute__((swift_name("members")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupDTO.Companion")))
@interface SharedChannelGroupDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelGroupDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupMemberDTO")))
@interface SharedChannelGroupMemberDTO : SharedBase
- (instancetype)initWithChannelId:(NSString *)channelId priority:(int32_t)priority channelName:(NSString * _Nullable)channelName __attribute__((swift_name("init(channelId:priority:channelName:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelGroupMemberDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelGroupMemberDTO *)doCopyChannelId:(NSString *)channelId priority:(int32_t)priority channelName:(NSString * _Nullable)channelName __attribute__((swift_name("doCopy(channelId:priority:channelName:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelName __attribute__((swift_name("channelName")));
@property (readonly) int32_t priority __attribute__((swift_name("priority")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupMemberDTO.Companion")))
@interface SharedChannelGroupMemberDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelGroupMemberDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupsResponse")))
@interface SharedChannelGroupsResponse : SharedBase
- (instancetype)initWithGroups:(NSArray<SharedChannelGroupDTO *> *)groups __attribute__((swift_name("init(groups:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelGroupsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelGroupsResponse *)doCopyGroups:(NSArray<SharedChannelGroupDTO *> *)groups __attribute__((swift_name("doCopy(groups:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedChannelGroupDTO *> *groups __attribute__((swift_name("groups")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupsResponse.Companion")))
@interface SharedChannelGroupsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelGroupsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelNowPlayingDTO")))
@interface SharedChannelNowPlayingDTO : SharedBase
- (instancetype)initWithChannelId:(NSString * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo program:(SharedProgramDTO * _Nullable)program __attribute__((swift_name("init(channelId:channelName:channelLogo:program:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelNowPlayingDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelNowPlayingDTO *)doCopyChannelId:(NSString * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo program:(SharedProgramDTO * _Nullable)program __attribute__((swift_name("doCopy(channelId:channelName:channelLogo:program:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelLogo __attribute__((swift_name("channelLogo")));
@property (readonly) NSString * _Nullable channelName __attribute__((swift_name("channelName")));
@property (readonly) SharedProgramDTO * _Nullable program __attribute__((swift_name("program")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelNowPlayingDTO.Companion")))
@interface SharedChannelNowPlayingDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelNowPlayingDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelStreamResponse")))
@interface SharedChannelStreamResponse : SharedBase
- (instancetype)initWithUrl:(NSString *)url format:(NSString * _Nullable)format __attribute__((swift_name("init(url:format:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelStreamResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelStreamResponse *)doCopyUrl:(NSString *)url format:(NSString * _Nullable)format __attribute__((swift_name("doCopy(url:format:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable format __attribute__((swift_name("format")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelStreamResponse.Companion")))
@interface SharedChannelStreamResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelStreamResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelsResponse")))
@interface SharedChannelsResponse : SharedBase
- (instancetype)initWithChannels:(NSArray<SharedChannelDTO *> * _Nullable)channels __attribute__((swift_name("init(channels:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedChannelsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedChannelsResponse *)doCopyChannels:(NSArray<SharedChannelDTO *> * _Nullable)channels __attribute__((swift_name("doCopy(channels:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedChannelDTO *> *allChannels __attribute__((swift_name("allChannels")));
@property (readonly) NSArray<SharedChannelDTO *> * _Nullable channels __attribute__((swift_name("channels")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelsResponse.Companion")))
@interface SharedChannelsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedChannelsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionDTO")))
@interface SharedCollectionDTO : SharedBase
- (instancetype)initWithRatingKey:(NSString *)ratingKey key:(NSString *)key type:(NSString *)type title:(NSString *)title summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art childCount:(SharedInt * _Nullable)childCount addedAt:(SharedInt * _Nullable)addedAt updatedAt:(SharedInt * _Nullable)updatedAt __attribute__((swift_name("init(ratingKey:key:type:title:summary:thumb:art:childCount:addedAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedCollectionDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedCollectionDTO *)doCopyRatingKey:(NSString *)ratingKey key:(NSString *)key type:(NSString *)type title:(NSString *)title summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art childCount:(SharedInt * _Nullable)childCount addedAt:(SharedInt * _Nullable)addedAt updatedAt:(SharedInt * _Nullable)updatedAt __attribute__((swift_name("doCopy(ratingKey:key:type:title:summary:thumb:art:childCount:addedAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedMediaCollection *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) SharedInt * _Nullable childCount __attribute__((swift_name("childCount")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) NSString *ratingKey __attribute__((swift_name("ratingKey")));
@property (readonly) NSString * _Nullable summary __attribute__((swift_name("summary")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) NSString *type __attribute__((swift_name("type")));
@property (readonly) SharedInt * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionDTO.Companion")))
@interface SharedCollectionDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedCollectionDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionsContainer")))
@interface SharedCollectionsContainer : SharedBase
- (instancetype)initWithMetadata:(NSArray<SharedCollectionDTO *> * _Nullable)Metadata __attribute__((swift_name("init(Metadata:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedCollectionsContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedCollectionsContainer *)doCopyMetadata:(NSArray<SharedCollectionDTO *> * _Nullable)Metadata __attribute__((swift_name("doCopy(Metadata:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedCollectionDTO *> * _Nullable Metadata __attribute__((swift_name("Metadata")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionsContainer.Companion")))
@interface SharedCollectionsContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedCollectionsContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionsResponse")))
@interface SharedCollectionsResponse : SharedBase
- (instancetype)initWithMediaContainer:(SharedCollectionsContainer *)MediaContainer __attribute__((swift_name("init(MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedCollectionsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedCollectionsResponse *)doCopyMediaContainer:(SharedCollectionsContainer *)MediaContainer __attribute__((swift_name("doCopy(MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedCollectionsContainer *MediaContainer __attribute__((swift_name("MediaContainer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CollectionsResponse.Companion")))
@interface SharedCollectionsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedCollectionsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CommercialDTO")))
@interface SharedCommercialDTO : SharedBase
- (instancetype)initWithStart:(int32_t)start end:(int32_t)end __attribute__((swift_name("init(start:end:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedCommercialDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedCommercialDTO *)doCopyStart:(int32_t)start end:(int32_t)end __attribute__((swift_name("doCopy(start:end:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t end __attribute__((swift_name("end")));
@property (readonly) int32_t start __attribute__((swift_name("start")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CommercialDTO.Companion")))
@interface SharedCommercialDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedCommercialDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CountryDTO")))
@interface SharedCountryDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("init(id:tag:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedCountryDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedCountryDTO *)doCopyId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("doCopy(id:tag:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString *tag __attribute__((swift_name("tag")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CountryDTO.Companion")))
@interface SharedCountryDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedCountryDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DirectorDTO")))
@interface SharedDirectorDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("init(id:tag:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedDirectorDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedDirectorDTO *)doCopyId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("doCopy(id:tag:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString *tag __attribute__((swift_name("tag")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DirectorDTO.Companion")))
@interface SharedDirectorDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedDirectorDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourceDTO")))
@interface SharedEPGSourceDTO : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name url:(NSString *)url type:(NSString *)type enabled:(SharedBoolean * _Nullable)enabled lastFetched:(NSString * _Nullable)lastFetched channelCount:(SharedInt * _Nullable)channelCount programCount:(SharedInt * _Nullable)programCount __attribute__((swift_name("init(id:name:url:type:enabled:lastFetched:channelCount:programCount:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedEPGSourceDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedEPGSourceDTO *)doCopyId:(int32_t)id name:(NSString *)name url:(NSString *)url type:(NSString *)type enabled:(SharedBoolean * _Nullable)enabled lastFetched:(NSString * _Nullable)lastFetched channelCount:(SharedInt * _Nullable)channelCount programCount:(SharedInt * _Nullable)programCount __attribute__((swift_name("doCopy(id:name:url:type:enabled:lastFetched:channelCount:programCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedEPGSource *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable channelCount __attribute__((swift_name("channelCount")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) SharedInt * _Nullable programCount __attribute__((swift_name("programCount")));
@property (readonly) NSString *type __attribute__((swift_name("type")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourceDTO.Companion")))
@interface SharedEPGSourceDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedEPGSourceDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourcesResponse")))
@interface SharedEPGSourcesResponse : SharedBase
- (instancetype)initWithSources:(NSArray<SharedEPGSourceDTO *> *)sources __attribute__((swift_name("init(sources:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedEPGSourcesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedEPGSourcesResponse *)doCopySources:(NSArray<SharedEPGSourceDTO *> *)sources __attribute__((swift_name("doCopy(sources:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedEPGSourceDTO *> *sources __attribute__((swift_name("sources")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourcesResponse.Companion")))
@interface SharedEPGSourcesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedEPGSourcesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GenreDTO")))
@interface SharedGenreDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("init(id:tag:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedGenreDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedGenreDTO *)doCopyId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("doCopy(id:tag:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString *tag __attribute__((swift_name("tag")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GenreDTO.Companion")))
@interface SharedGenreDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedGenreDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GuideResponse")))
@interface SharedGuideResponse : SharedBase
- (instancetype)initWithChannels:(NSArray<SharedChannelDTO *> * _Nullable)channels programs:(NSDictionary<NSString *, NSArray<SharedProgramDTO *> *> * _Nullable)programs start:(NSString * _Nullable)start end:(NSString * _Nullable)end __attribute__((swift_name("init(channels:programs:start:end:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedGuideResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedGuideResponse *)doCopyChannels:(NSArray<SharedChannelDTO *> * _Nullable)channels programs:(NSDictionary<NSString *, NSArray<SharedProgramDTO *> *> * _Nullable)programs start:(NSString * _Nullable)start end:(NSString * _Nullable)end __attribute__((swift_name("doCopy(channels:programs:start:end:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSArray<SharedProgramDTO *> *)programsForChannelId:(NSString *)id __attribute__((swift_name("programsForChannel(id:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedChannelDTO *> *allChannels __attribute__((swift_name("allChannels")));
@property (readonly) NSArray<SharedChannelDTO *> * _Nullable channels __attribute__((swift_name("channels")));
@property (readonly) NSString * _Nullable end __attribute__((swift_name("end")));
@property (readonly) NSDictionary<NSString *, NSArray<SharedProgramDTO *> *> * _Nullable programs __attribute__((swift_name("programs")));
@property (readonly) NSString * _Nullable start __attribute__((swift_name("start")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("GuideResponse.Companion")))
@interface SharedGuideResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedGuideResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HomeUserDTO")))
@interface SharedHomeUserDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id uuid:(NSString *)uuid title:(NSString *)title username:(NSString * _Nullable)username thumb:(NSString * _Nullable)thumb hasPassword:(SharedBoolean * _Nullable)hasPassword restricted:(SharedBoolean * _Nullable)restricted admin:(SharedBoolean * _Nullable)admin guest:(SharedBoolean * _Nullable)guest protected:(SharedBoolean * _Nullable)protected_ __attribute__((swift_name("init(id:uuid:title:username:thumb:hasPassword:restricted:admin:guest:protected:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedHomeUserDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedHomeUserDTO *)doCopyId:(SharedInt * _Nullable)id uuid:(NSString *)uuid title:(NSString *)title username:(NSString * _Nullable)username thumb:(NSString * _Nullable)thumb hasPassword:(SharedBoolean * _Nullable)hasPassword restricted:(SharedBoolean * _Nullable)restricted admin:(SharedBoolean * _Nullable)admin guest:(SharedBoolean * _Nullable)guest protected:(SharedBoolean * _Nullable)protected_ __attribute__((swift_name("doCopy(id:uuid:title:username:thumb:hasPassword:restricted:admin:guest:protected:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedProfile *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedBoolean * _Nullable admin __attribute__((swift_name("admin")));
@property (readonly) SharedBoolean * _Nullable guest __attribute__((swift_name("guest")));
@property (readonly) SharedBoolean * _Nullable hasPassword __attribute__((swift_name("hasPassword")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly, getter=protected) SharedBoolean * _Nullable protected_ __attribute__((swift_name("protected_")));
@property (readonly) SharedBoolean * _Nullable restricted __attribute__((swift_name("restricted")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable username __attribute__((swift_name("username")));
@property (readonly) NSString *uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HomeUserDTO.Companion")))
@interface SharedHomeUserDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedHomeUserDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HomeUsersResponse")))
@interface SharedHomeUsersResponse : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id name:(NSString * _Nullable)name users:(NSArray<SharedHomeUserDTO *> *)users __attribute__((swift_name("init(id:name:users:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedHomeUsersResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedHomeUsersResponse *)doCopyId:(SharedInt * _Nullable)id name:(NSString * _Nullable)name users:(NSArray<SharedHomeUserDTO *> *)users __attribute__((swift_name("doCopy(id:name:users:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) NSArray<SharedHomeUserDTO *> *users __attribute__((swift_name("users")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HomeUsersResponse.Companion")))
@interface SharedHomeUsersResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedHomeUsersResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubDTO")))
@interface SharedHubDTO : SharedBase
- (instancetype)initWithKey:(NSString * _Nullable)key hubKey:(NSString * _Nullable)hubKey type:(NSString * _Nullable)type hubIdentifier:(NSString * _Nullable)hubIdentifier title:(NSString * _Nullable)title context:(NSString * _Nullable)context size:(SharedInt * _Nullable)size more:(SharedBoolean * _Nullable)more style:(NSString * _Nullable)style promoted:(SharedBoolean * _Nullable)promoted Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata __attribute__((swift_name("init(key:hubKey:type:hubIdentifier:title:context:size:more:style:promoted:Metadata:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedHubDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedHubDTO *)doCopyKey:(NSString * _Nullable)key hubKey:(NSString * _Nullable)hubKey type:(NSString * _Nullable)type hubIdentifier:(NSString * _Nullable)hubIdentifier title:(NSString * _Nullable)title context:(NSString * _Nullable)context size:(SharedInt * _Nullable)size more:(SharedBoolean * _Nullable)more style:(NSString * _Nullable)style promoted:(SharedBoolean * _Nullable)promoted Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata __attribute__((swift_name("doCopy(key:hubKey:type:hubIdentifier:title:context:size:more:style:promoted:Metadata:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedHub *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedMediaItemDTO *> * _Nullable Metadata __attribute__((swift_name("Metadata")));
@property (readonly) NSString * _Nullable context __attribute__((swift_name("context")));
@property (readonly) NSString * _Nullable hubIdentifier __attribute__((swift_name("hubIdentifier")));
@property (readonly) NSString * _Nullable hubKey __attribute__((swift_name("hubKey")));
@property (readonly) NSString * _Nullable key __attribute__((swift_name("key")));
@property (readonly) SharedBoolean * _Nullable more __attribute__((swift_name("more")));
@property (readonly) SharedBoolean * _Nullable promoted __attribute__((swift_name("promoted")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@property (readonly) NSString * _Nullable style __attribute__((swift_name("style")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable type __attribute__((swift_name("type")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubDTO.Companion")))
@interface SharedHubDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedHubDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubsContainer")))
@interface SharedHubsContainer : SharedBase
- (instancetype)initWithSize:(SharedInt * _Nullable)size librarySectionID:(SharedInt * _Nullable)librarySectionID Hub:(NSArray<SharedHubDTO *> * _Nullable)Hub __attribute__((swift_name("init(size:librarySectionID:Hub:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedHubsContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedHubsContainer *)doCopySize:(SharedInt * _Nullable)size librarySectionID:(SharedInt * _Nullable)librarySectionID Hub:(NSArray<SharedHubDTO *> * _Nullable)Hub __attribute__((swift_name("doCopy(size:librarySectionID:Hub:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedHubDTO *> * _Nullable Hub __attribute__((swift_name("Hub")));
@property (readonly) SharedInt * _Nullable librarySectionID __attribute__((swift_name("librarySectionID")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubsContainer.Companion")))
@interface SharedHubsContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedHubsContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubsResponse")))
@interface SharedHubsResponse : SharedBase
- (instancetype)initWithMediaContainer:(SharedHubsContainer * _Nullable)MediaContainer __attribute__((swift_name("init(MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedHubsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedHubsResponse *)doCopyMediaContainer:(SharedHubsContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedHubsContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("HubsResponse.Companion")))
@interface SharedHubsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedHubsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LeaguesResponse")))
@interface SharedLeaguesResponse : SharedBase
- (instancetype)initWithLeagues:(NSArray<NSString *> *)leagues __attribute__((swift_name("init(leagues:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedLeaguesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedLeaguesResponse *)doCopyLeagues:(NSArray<NSString *> *)leagues __attribute__((swift_name("doCopy(leagues:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<NSString *> *leagues __attribute__((swift_name("leagues")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LeaguesResponse.Companion")))
@interface SharedLeaguesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedLeaguesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionDTO")))
@interface SharedLibrarySectionDTO : SharedBase
- (instancetype)initWithKey:(NSString *)key type:(NSString *)type title:(NSString *)title agent:(NSString * _Nullable)agent scanner:(NSString * _Nullable)scanner language:(NSString * _Nullable)language uuid:(NSString * _Nullable)uuid updatedAt:(SharedInt * _Nullable)updatedAt scannedAt:(SharedInt * _Nullable)scannedAt createdAt:(SharedInt * _Nullable)createdAt hidden:(SharedInt * _Nullable)hidden count:(SharedInt * _Nullable)count __attribute__((swift_name("init(key:type:title:agent:scanner:language:uuid:updatedAt:scannedAt:createdAt:hidden:count:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedLibrarySectionDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedLibrarySectionDTO *)doCopyKey:(NSString *)key type:(NSString *)type title:(NSString *)title agent:(NSString * _Nullable)agent scanner:(NSString * _Nullable)scanner language:(NSString * _Nullable)language uuid:(NSString * _Nullable)uuid updatedAt:(SharedInt * _Nullable)updatedAt scannedAt:(SharedInt * _Nullable)scannedAt createdAt:(SharedInt * _Nullable)createdAt hidden:(SharedInt * _Nullable)hidden count:(SharedInt * _Nullable)count __attribute__((swift_name("doCopy(key:type:title:agent:scanner:language:uuid:updatedAt:scannedAt:createdAt:hidden:count:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedLibrarySection *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable agent __attribute__((swift_name("agent")));
@property (readonly) SharedInt * _Nullable count __attribute__((swift_name("count")));
@property (readonly) SharedInt * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) SharedInt * _Nullable hidden __attribute__((swift_name("hidden")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) NSString * _Nullable language __attribute__((swift_name("language")));
@property (readonly) SharedInt * _Nullable scannedAt __attribute__((swift_name("scannedAt")));
@property (readonly) NSString * _Nullable scanner __attribute__((swift_name("scanner")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) NSString *type __attribute__((swift_name("type")));
@property (readonly) SharedInt * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@property (readonly) NSString * _Nullable uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionDTO.Companion")))
@interface SharedLibrarySectionDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedLibrarySectionDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionsContainer")))
@interface SharedLibrarySectionsContainer : SharedBase
- (instancetype)initWithSize:(SharedInt * _Nullable)size Directory:(NSArray<SharedLibrarySectionDTO *> * _Nullable)Directory directories:(NSArray<SharedLibrarySectionDTO *> * _Nullable)directories __attribute__((swift_name("init(size:Directory:directories:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedLibrarySectionsContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedLibrarySectionsContainer *)doCopySize:(SharedInt * _Nullable)size Directory:(NSArray<SharedLibrarySectionDTO *> * _Nullable)Directory directories:(NSArray<SharedLibrarySectionDTO *> * _Nullable)directories __attribute__((swift_name("doCopy(size:Directory:directories:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedLibrarySectionDTO *> * _Nullable Directory __attribute__((swift_name("Directory")));
@property (readonly) NSArray<SharedLibrarySectionDTO *> *allDirectories __attribute__((swift_name("allDirectories")));
@property (readonly) NSArray<SharedLibrarySectionDTO *> * _Nullable directories __attribute__((swift_name("directories")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionsContainer.Companion")))
@interface SharedLibrarySectionsContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedLibrarySectionsContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionsResponse")))
@interface SharedLibrarySectionsResponse : SharedBase
- (instancetype)initWithMediaContainer:(SharedLibrarySectionsContainer * _Nullable)MediaContainer __attribute__((swift_name("init(MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedLibrarySectionsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedLibrarySectionsResponse *)doCopyMediaContainer:(SharedLibrarySectionsContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedLibrarySectionsContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionsResponse.Companion")))
@interface SharedLibrarySectionsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedLibrarySectionsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("M3USourceDTO")))
@interface SharedM3USourceDTO : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name url:(NSString *)url epgUrl:(NSString * _Nullable)epgUrl enabled:(SharedBoolean * _Nullable)enabled lastFetched:(NSString * _Nullable)lastFetched importVod:(SharedBoolean * _Nullable)importVod importSeries:(SharedBoolean * _Nullable)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(SharedInt * _Nullable)channelCount __attribute__((swift_name("init(id:name:url:epgUrl:enabled:lastFetched:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedM3USourceDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedM3USourceDTO *)doCopyId:(int32_t)id name:(NSString *)name url:(NSString *)url epgUrl:(NSString * _Nullable)epgUrl enabled:(SharedBoolean * _Nullable)enabled lastFetched:(NSString * _Nullable)lastFetched importVod:(SharedBoolean * _Nullable)importVod importSeries:(SharedBoolean * _Nullable)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(SharedInt * _Nullable)channelCount __attribute__((swift_name("doCopy(id:name:url:epgUrl:enabled:lastFetched:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedM3USource *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable channelCount __attribute__((swift_name("channelCount")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) NSString * _Nullable epgUrl __attribute__((swift_name("epgUrl")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable importSeries __attribute__((swift_name("importSeries")));
@property (readonly) SharedBoolean * _Nullable importVod __attribute__((swift_name("importVod")));
@property (readonly) NSString * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) SharedInt * _Nullable seriesLibraryId __attribute__((swift_name("seriesLibraryId")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@property (readonly) SharedInt * _Nullable vodLibraryId __attribute__((swift_name("vodLibraryId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("M3USourceDTO.Companion")))
@interface SharedM3USourceDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedM3USourceDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("M3USourcesResponse")))
@interface SharedM3USourcesResponse : SharedBase
- (instancetype)initWithSources:(NSArray<SharedM3USourceDTO *> *)sources __attribute__((swift_name("init(sources:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedM3USourcesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedM3USourcesResponse *)doCopySources:(NSArray<SharedM3USourceDTO *> *)sources __attribute__((swift_name("doCopy(sources:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedM3USourceDTO *> *sources __attribute__((swift_name("sources")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("M3USourcesResponse.Companion")))
@interface SharedM3USourcesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedM3USourcesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaContainer")))
@interface SharedMediaContainer : SharedBase
- (instancetype)initWithSize:(SharedInt * _Nullable)size totalSize:(SharedInt * _Nullable)totalSize offset:(SharedInt * _Nullable)offset allowSync:(SharedBoolean * _Nullable)allowSync identifier:(NSString * _Nullable)identifier librarySectionID:(SharedInt * _Nullable)librarySectionID librarySectionTitle:(NSString * _Nullable)librarySectionTitle librarySectionUUID:(NSString * _Nullable)librarySectionUUID Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata Hub:(NSArray<SharedHubDTO *> * _Nullable)Hub Directory:(NSArray<SharedLibrarySectionDTO *> * _Nullable)Directory __attribute__((swift_name("init(size:totalSize:offset:allowSync:identifier:librarySectionID:librarySectionTitle:librarySectionUUID:Metadata:Hub:Directory:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedMediaContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedMediaContainer *)doCopySize:(SharedInt * _Nullable)size totalSize:(SharedInt * _Nullable)totalSize offset:(SharedInt * _Nullable)offset allowSync:(SharedBoolean * _Nullable)allowSync identifier:(NSString * _Nullable)identifier librarySectionID:(SharedInt * _Nullable)librarySectionID librarySectionTitle:(NSString * _Nullable)librarySectionTitle librarySectionUUID:(NSString * _Nullable)librarySectionUUID Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata Hub:(NSArray<SharedHubDTO *> * _Nullable)Hub Directory:(NSArray<SharedLibrarySectionDTO *> * _Nullable)Directory __attribute__((swift_name("doCopy(size:totalSize:offset:allowSync:identifier:librarySectionID:librarySectionTitle:librarySectionUUID:Metadata:Hub:Directory:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedLibrarySectionDTO *> * _Nullable Directory __attribute__((swift_name("Directory")));
@property (readonly) NSArray<SharedHubDTO *> * _Nullable Hub __attribute__((swift_name("Hub")));
@property (readonly) NSArray<SharedMediaItemDTO *> * _Nullable Metadata __attribute__((swift_name("Metadata")));
@property (readonly) SharedBoolean * _Nullable allowSync __attribute__((swift_name("allowSync")));
@property (readonly) NSString * _Nullable identifier __attribute__((swift_name("identifier")));
@property (readonly) SharedInt * _Nullable librarySectionID __attribute__((swift_name("librarySectionID")));
@property (readonly) NSString * _Nullable librarySectionTitle __attribute__((swift_name("librarySectionTitle")));
@property (readonly) NSString * _Nullable librarySectionUUID __attribute__((swift_name("librarySectionUUID")));
@property (readonly) SharedInt * _Nullable offset __attribute__((swift_name("offset")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@property (readonly) SharedInt * _Nullable totalSize __attribute__((swift_name("totalSize")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaContainer.Companion")))
@interface SharedMediaContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaContainerResponse")))
@interface SharedMediaContainerResponse : SharedBase
- (instancetype)initWithMediaContainer:(SharedMediaContainer * _Nullable)MediaContainer __attribute__((swift_name("init(MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedMediaContainerResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedMediaContainerResponse *)doCopyMediaContainer:(SharedMediaContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedMediaContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaContainerResponse.Companion")))
@interface SharedMediaContainerResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaContainerResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaItemDTO")))
@interface SharedMediaItemDTO : SharedBase
- (instancetype)initWithRatingKeyValue:(SharedStringOrInt * _Nullable)ratingKeyValue key:(NSString * _Nullable)key guid:(NSString * _Nullable)guid type:(NSString * _Nullable)type title:(NSString * _Nullable)title originalTitle:(NSString * _Nullable)originalTitle tagline:(NSString * _Nullable)tagline summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art banner:(NSString * _Nullable)banner year:(SharedInt * _Nullable)year duration:(SharedInt * _Nullable)duration viewOffset:(SharedInt * _Nullable)viewOffset viewCount:(SharedInt * _Nullable)viewCount contentRating:(NSString * _Nullable)contentRating audienceRating:(SharedDouble * _Nullable)audienceRating rating:(SharedDouble * _Nullable)rating studio:(NSString * _Nullable)studio addedAt:(SharedInt * _Nullable)addedAt updatedAt:(SharedInt * _Nullable)updatedAt originallyAvailableAt:(NSString * _Nullable)originallyAvailableAt leafCount:(SharedInt * _Nullable)leafCount viewedLeafCount:(SharedInt * _Nullable)viewedLeafCount childCount:(SharedInt * _Nullable)childCount index:(SharedInt * _Nullable)index parentIndex:(SharedInt * _Nullable)parentIndex parentRatingKey:(SharedStringOrInt * _Nullable)parentRatingKey parentTitle:(NSString * _Nullable)parentTitle parentThumb:(NSString * _Nullable)parentThumb grandparentRatingKey:(SharedStringOrInt * _Nullable)grandparentRatingKey grandparentTitle:(NSString * _Nullable)grandparentTitle grandparentThumb:(NSString * _Nullable)grandparentThumb grandparentArt:(NSString * _Nullable)grandparentArt librarySectionID:(SharedInt * _Nullable)librarySectionID librarySectionTitle:(NSString * _Nullable)librarySectionTitle Genre:(NSArray<SharedGenreDTO *> * _Nullable)Genre Role:(NSArray<SharedRoleDTO *> * _Nullable)Role Director:(NSArray<SharedDirectorDTO *> * _Nullable)Director Writer:(NSArray<SharedWriterDTO *> * _Nullable)Writer Country:(NSArray<SharedCountryDTO *> * _Nullable)Country Media:(NSArray<SharedMediaVersionDTO *> * _Nullable)Media __attribute__((swift_name("init(ratingKeyValue:key:guid:type:title:originalTitle:tagline:summary:thumb:art:banner:year:duration:viewOffset:viewCount:contentRating:audienceRating:rating:studio:addedAt:updatedAt:originallyAvailableAt:leafCount:viewedLeafCount:childCount:index:parentIndex:parentRatingKey:parentTitle:parentThumb:grandparentRatingKey:grandparentTitle:grandparentThumb:grandparentArt:librarySectionID:librarySectionTitle:Genre:Role:Director:Writer:Country:Media:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedMediaItemDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedMediaItemDTO *)doCopyRatingKeyValue:(SharedStringOrInt * _Nullable)ratingKeyValue key:(NSString * _Nullable)key guid:(NSString * _Nullable)guid type:(NSString * _Nullable)type title:(NSString * _Nullable)title originalTitle:(NSString * _Nullable)originalTitle tagline:(NSString * _Nullable)tagline summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art banner:(NSString * _Nullable)banner year:(SharedInt * _Nullable)year duration:(SharedInt * _Nullable)duration viewOffset:(SharedInt * _Nullable)viewOffset viewCount:(SharedInt * _Nullable)viewCount contentRating:(NSString * _Nullable)contentRating audienceRating:(SharedDouble * _Nullable)audienceRating rating:(SharedDouble * _Nullable)rating studio:(NSString * _Nullable)studio addedAt:(SharedInt * _Nullable)addedAt updatedAt:(SharedInt * _Nullable)updatedAt originallyAvailableAt:(NSString * _Nullable)originallyAvailableAt leafCount:(SharedInt * _Nullable)leafCount viewedLeafCount:(SharedInt * _Nullable)viewedLeafCount childCount:(SharedInt * _Nullable)childCount index:(SharedInt * _Nullable)index parentIndex:(SharedInt * _Nullable)parentIndex parentRatingKey:(SharedStringOrInt * _Nullable)parentRatingKey parentTitle:(NSString * _Nullable)parentTitle parentThumb:(NSString * _Nullable)parentThumb grandparentRatingKey:(SharedStringOrInt * _Nullable)grandparentRatingKey grandparentTitle:(NSString * _Nullable)grandparentTitle grandparentThumb:(NSString * _Nullable)grandparentThumb grandparentArt:(NSString * _Nullable)grandparentArt librarySectionID:(SharedInt * _Nullable)librarySectionID librarySectionTitle:(NSString * _Nullable)librarySectionTitle Genre:(NSArray<SharedGenreDTO *> * _Nullable)Genre Role:(NSArray<SharedRoleDTO *> * _Nullable)Role Director:(NSArray<SharedDirectorDTO *> * _Nullable)Director Writer:(NSArray<SharedWriterDTO *> * _Nullable)Writer Country:(NSArray<SharedCountryDTO *> * _Nullable)Country Media:(NSArray<SharedMediaVersionDTO *> * _Nullable)Media __attribute__((swift_name("doCopy(ratingKeyValue:key:guid:type:title:originalTitle:tagline:summary:thumb:art:banner:year:duration:viewOffset:viewCount:contentRating:audienceRating:rating:studio:addedAt:updatedAt:originallyAvailableAt:leafCount:viewedLeafCount:childCount:index:parentIndex:parentRatingKey:parentTitle:parentThumb:grandparentRatingKey:grandparentTitle:grandparentThumb:grandparentArt:librarySectionID:librarySectionTitle:Genre:Role:Director:Writer:Country:Media:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedMediaItem *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedCountryDTO *> * _Nullable Country __attribute__((swift_name("Country")));
@property (readonly) NSArray<SharedDirectorDTO *> * _Nullable Director __attribute__((swift_name("Director")));
@property (readonly) NSArray<SharedGenreDTO *> * _Nullable Genre __attribute__((swift_name("Genre")));
@property (readonly) NSArray<SharedMediaVersionDTO *> * _Nullable Media __attribute__((swift_name("Media")));
@property (readonly) NSArray<SharedRoleDTO *> * _Nullable Role __attribute__((swift_name("Role")));
@property (readonly) NSArray<SharedWriterDTO *> * _Nullable Writer __attribute__((swift_name("Writer")));
@property (readonly) SharedInt * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) SharedDouble * _Nullable audienceRating __attribute__((swift_name("audienceRating")));
@property (readonly) NSString * _Nullable banner __attribute__((swift_name("banner")));
@property (readonly) SharedInt * _Nullable childCount __attribute__((swift_name("childCount")));
@property (readonly) NSString * _Nullable contentRating __attribute__((swift_name("contentRating")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable grandparentArt __attribute__((swift_name("grandparentArt")));
@property (readonly) SharedStringOrInt * _Nullable grandparentRatingKey __attribute__((swift_name("grandparentRatingKey")));
@property (readonly) NSString * _Nullable grandparentThumb __attribute__((swift_name("grandparentThumb")));
@property (readonly) NSString * _Nullable grandparentTitle __attribute__((swift_name("grandparentTitle")));
@property (readonly) NSString * _Nullable guid __attribute__((swift_name("guid")));
@property (readonly) SharedInt * _Nullable index __attribute__((swift_name("index")));
@property (readonly) NSString * _Nullable key __attribute__((swift_name("key")));
@property (readonly) SharedInt * _Nullable leafCount __attribute__((swift_name("leafCount")));
@property (readonly) SharedInt * _Nullable librarySectionID __attribute__((swift_name("librarySectionID")));
@property (readonly) NSString * _Nullable librarySectionTitle __attribute__((swift_name("librarySectionTitle")));
@property (readonly) NSString * _Nullable originalTitle __attribute__((swift_name("originalTitle")));
@property (readonly) NSString * _Nullable originallyAvailableAt __attribute__((swift_name("originallyAvailableAt")));
@property (readonly) SharedInt * _Nullable parentIndex __attribute__((swift_name("parentIndex")));
@property (readonly) SharedStringOrInt * _Nullable parentRatingKey __attribute__((swift_name("parentRatingKey")));
@property (readonly) NSString * _Nullable parentThumb __attribute__((swift_name("parentThumb")));
@property (readonly) NSString * _Nullable parentTitle __attribute__((swift_name("parentTitle")));
@property (readonly) SharedDouble * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) int32_t ratingKeyInt __attribute__((swift_name("ratingKeyInt")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="ratingKey")
*/
@property (readonly) SharedStringOrInt * _Nullable ratingKeyValue __attribute__((swift_name("ratingKeyValue")));
@property (readonly) NSString *safeKey __attribute__((swift_name("safeKey")));
@property (readonly) NSString *safeTitle __attribute__((swift_name("safeTitle")));
@property (readonly) NSString *safeType __attribute__((swift_name("safeType")));
@property (readonly) NSString * _Nullable studio __attribute__((swift_name("studio")));
@property (readonly) NSString * _Nullable summary __attribute__((swift_name("summary")));
@property (readonly) NSString * _Nullable tagline __attribute__((swift_name("tagline")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable type __attribute__((swift_name("type")));
@property (readonly) SharedInt * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@property (readonly) SharedInt * _Nullable viewCount __attribute__((swift_name("viewCount")));
@property (readonly) SharedInt * _Nullable viewOffset __attribute__((swift_name("viewOffset")));
@property (readonly) SharedInt * _Nullable viewedLeafCount __attribute__((swift_name("viewedLeafCount")));
@property (readonly) SharedInt * _Nullable year __attribute__((swift_name("year")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaItemDTO.Companion")))
@interface SharedMediaItemDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaItemDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaPartDTO")))
@interface SharedMediaPartDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id key:(NSString * _Nullable)key duration:(SharedInt * _Nullable)duration file:(NSString * _Nullable)file size:(SharedInt * _Nullable)size container:(NSString * _Nullable)container Stream:(NSArray<SharedStreamDTO *> * _Nullable)Stream __attribute__((swift_name("init(id:key:duration:file:size:container:Stream:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedMediaPartDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedMediaPartDTO *)doCopyId:(SharedInt * _Nullable)id key:(NSString * _Nullable)key duration:(SharedInt * _Nullable)duration file:(NSString * _Nullable)file size:(SharedInt * _Nullable)size container:(NSString * _Nullable)container Stream:(NSArray<SharedStreamDTO *> * _Nullable)Stream __attribute__((swift_name("doCopy(id:key:duration:file:size:container:Stream:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedMediaPart *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedStreamDTO *> * _Nullable Stream __attribute__((swift_name("Stream")));
@property (readonly) NSString * _Nullable container __attribute__((swift_name("container")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable file __attribute__((swift_name("file")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable key __attribute__((swift_name("key")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaPartDTO.Companion")))
@interface SharedMediaPartDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaPartDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaVersionDTO")))
@interface SharedMediaVersionDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id duration:(SharedInt * _Nullable)duration bitrate:(SharedInt * _Nullable)bitrate width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height aspectRatio:(SharedDouble * _Nullable)aspectRatio audioChannels:(SharedInt * _Nullable)audioChannels audioCodec:(NSString * _Nullable)audioCodec videoCodec:(NSString * _Nullable)videoCodec videoResolution:(NSString * _Nullable)videoResolution container:(NSString * _Nullable)container videoFrameRate:(NSString * _Nullable)videoFrameRate Part:(NSArray<SharedMediaPartDTO *> * _Nullable)Part __attribute__((swift_name("init(id:duration:bitrate:width:height:aspectRatio:audioChannels:audioCodec:videoCodec:videoResolution:container:videoFrameRate:Part:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedMediaVersionDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedMediaVersionDTO *)doCopyId:(SharedInt * _Nullable)id duration:(SharedInt * _Nullable)duration bitrate:(SharedInt * _Nullable)bitrate width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height aspectRatio:(SharedDouble * _Nullable)aspectRatio audioChannels:(SharedInt * _Nullable)audioChannels audioCodec:(NSString * _Nullable)audioCodec videoCodec:(NSString * _Nullable)videoCodec videoResolution:(NSString * _Nullable)videoResolution container:(NSString * _Nullable)container videoFrameRate:(NSString * _Nullable)videoFrameRate Part:(NSArray<SharedMediaPartDTO *> * _Nullable)Part __attribute__((swift_name("doCopy(id:duration:bitrate:width:height:aspectRatio:audioChannels:audioCodec:videoCodec:videoResolution:container:videoFrameRate:Part:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedMediaVersion *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedMediaPartDTO *> * _Nullable Part __attribute__((swift_name("Part")));
@property (readonly) SharedDouble * _Nullable aspectRatio __attribute__((swift_name("aspectRatio")));
@property (readonly) SharedInt * _Nullable audioChannels __attribute__((swift_name("audioChannels")));
@property (readonly) NSString * _Nullable audioCodec __attribute__((swift_name("audioCodec")));
@property (readonly) SharedInt * _Nullable bitrate __attribute__((swift_name("bitrate")));
@property (readonly) NSString * _Nullable container __attribute__((swift_name("container")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) SharedInt * _Nullable height __attribute__((swift_name("height")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable videoCodec __attribute__((swift_name("videoCodec")));
@property (readonly) NSString * _Nullable videoFrameRate __attribute__((swift_name("videoFrameRate")));
@property (readonly) NSString * _Nullable videoResolution __attribute__((swift_name("videoResolution")));
@property (readonly) SharedInt * _Nullable width __attribute__((swift_name("width")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaVersionDTO.Companion")))
@interface SharedMediaVersionDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaVersionDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NowPlayingResponse")))
@interface SharedNowPlayingResponse : SharedBase
- (instancetype)initWithChannels:(NSArray<SharedChannelNowPlayingDTO *> * _Nullable)channels __attribute__((swift_name("init(channels:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedNowPlayingResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedNowPlayingResponse *)doCopyChannels:(NSArray<SharedChannelNowPlayingDTO *> * _Nullable)channels __attribute__((swift_name("doCopy(channels:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedChannelNowPlayingDTO *> * _Nullable channels __attribute__((swift_name("channels")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NowPlayingResponse.Companion")))
@interface SharedNowPlayingResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNowPlayingResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterProgramDTO")))
@interface SharedOnLaterProgramDTO : SharedBase
- (instancetype)initWithChannelId:(NSString *)channelId channelName:(NSString *)channelName channelLogo:(NSString * _Nullable)channelLogo channelNumber:(SharedInt * _Nullable)channelNumber program:(SharedProgramDTO *)program __attribute__((swift_name("init(channelId:channelName:channelLogo:channelNumber:program:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedOnLaterProgramDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedOnLaterProgramDTO *)doCopyChannelId:(NSString *)channelId channelName:(NSString *)channelName channelLogo:(NSString * _Nullable)channelLogo channelNumber:(SharedInt * _Nullable)channelNumber program:(SharedProgramDTO *)program __attribute__((swift_name("doCopy(channelId:channelName:channelLogo:channelNumber:program:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedOnLaterProgram *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelLogo __attribute__((swift_name("channelLogo")));
@property (readonly) NSString *channelName __attribute__((swift_name("channelName")));
@property (readonly) SharedInt * _Nullable channelNumber __attribute__((swift_name("channelNumber")));
@property (readonly) SharedProgramDTO *program __attribute__((swift_name("program")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterProgramDTO.Companion")))
@interface SharedOnLaterProgramDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedOnLaterProgramDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterResponse")))
@interface SharedOnLaterResponse : SharedBase
- (instancetype)initWithPrograms:(NSArray<SharedOnLaterProgramDTO *> *)programs __attribute__((swift_name("init(programs:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedOnLaterResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedOnLaterResponse *)doCopyPrograms:(NSArray<SharedOnLaterProgramDTO *> *)programs __attribute__((swift_name("doCopy(programs:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedOnLaterProgramDTO *> *programs __attribute__((swift_name("programs")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterResponse.Companion")))
@interface SharedOnLaterResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedOnLaterResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterStatsResponseDTO")))
@interface SharedOnLaterStatsResponseDTO : SharedBase
- (instancetype)initWithMovies:(int32_t)movies sports:(int32_t)sports kids:(int32_t)kids news:(int32_t)news premieres:(int32_t)premieres __attribute__((swift_name("init(movies:sports:kids:news:premieres:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedOnLaterStatsResponseDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedOnLaterStatsResponseDTO *)doCopyMovies:(int32_t)movies sports:(int32_t)sports kids:(int32_t)kids news:(int32_t)news premieres:(int32_t)premieres __attribute__((swift_name("doCopy(movies:sports:kids:news:premieres:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedOnLaterStats *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t kids __attribute__((swift_name("kids")));
@property (readonly) int32_t movies __attribute__((swift_name("movies")));
@property (readonly) int32_t news __attribute__((swift_name("news")));
@property (readonly) int32_t premieres __attribute__((swift_name("premieres")));
@property (readonly) int32_t sports __attribute__((swift_name("sports")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterStatsResponseDTO.Companion")))
@interface SharedOnLaterStatsResponseDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedOnLaterStatsResponseDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaybackURLResponse")))
@interface SharedPlaybackURLResponse : SharedBase
- (instancetype)initWithUrl:(NSString *)url protocol_:(NSString * _Nullable)protocol_ directPlay:(SharedBoolean * _Nullable)directPlay transcoding:(SharedBoolean * _Nullable)transcoding __attribute__((swift_name("init(url:protocol_:directPlay:transcoding:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaybackURLResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaybackURLResponse *)doCopyUrl:(NSString *)url protocol_:(NSString * _Nullable)protocol_ directPlay:(SharedBoolean * _Nullable)directPlay transcoding:(SharedBoolean * _Nullable)transcoding __attribute__((swift_name("doCopy(url:protocol_:directPlay:transcoding:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="direct_play")
*/
@property (readonly) SharedBoolean * _Nullable directPlay __attribute__((swift_name("directPlay")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="protocol")
*/
@property (readonly) NSString * _Nullable protocol_ __attribute__((swift_name("protocol_")));
@property (readonly) SharedBoolean * _Nullable transcoding __attribute__((swift_name("transcoding")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaybackURLResponse.Companion")))
@interface SharedPlaybackURLResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaybackURLResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistDTO")))
@interface SharedPlaylistDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id ratingKey:(NSString * _Nullable)ratingKey name:(NSString * _Nullable)name title:(NSString * _Nullable)title itemCount:(SharedInt * _Nullable)itemCount leafCount:(SharedInt * _Nullable)leafCount duration:(SharedInt * _Nullable)duration thumb:(NSString * _Nullable)thumb createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("init(id:ratingKey:name:title:itemCount:leafCount:duration:thumb:createdAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaylistDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaylistDTO *)doCopyId:(SharedInt * _Nullable)id ratingKey:(NSString * _Nullable)ratingKey name:(NSString * _Nullable)name title:(NSString * _Nullable)title itemCount:(SharedInt * _Nullable)itemCount leafCount:(SharedInt * _Nullable)leafCount duration:(SharedInt * _Nullable)duration thumb:(NSString * _Nullable)thumb createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("doCopy(id:ratingKey:name:title:itemCount:leafCount:duration:thumb:createdAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedPlaylist *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable itemCount __attribute__((swift_name("itemCount")));
@property (readonly) SharedInt * _Nullable leafCount __attribute__((swift_name("leafCount")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) NSString * _Nullable ratingKey __attribute__((swift_name("ratingKey")));
@property (readonly) int32_t safeId __attribute__((swift_name("safeId")));
@property (readonly) NSString *safeName __attribute__((swift_name("safeName")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistDTO.Companion")))
@interface SharedPlaylistDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaylistDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistItemDTO")))
@interface SharedPlaylistItemDTO : SharedBase
- (instancetype)initWithId:(int32_t)id playlistId:(int32_t)playlistId mediaId:(int32_t)mediaId index:(int32_t)index addedAt:(NSString * _Nullable)addedAt media:(SharedMediaItemDTO * _Nullable)media __attribute__((swift_name("init(id:playlistId:mediaId:index:addedAt:media:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaylistItemDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaylistItemDTO *)doCopyId:(int32_t)id playlistId:(int32_t)playlistId mediaId:(int32_t)mediaId index:(int32_t)index addedAt:(NSString * _Nullable)addedAt media:(SharedMediaItemDTO * _Nullable)media __attribute__((swift_name("doCopy(id:playlistId:mediaId:index:addedAt:media:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedPlaylistItem *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) int32_t index __attribute__((swift_name("index")));
@property (readonly) SharedMediaItemDTO * _Nullable media __attribute__((swift_name("media")));
@property (readonly) int32_t mediaId __attribute__((swift_name("mediaId")));
@property (readonly) int32_t playlistId __attribute__((swift_name("playlistId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistItemDTO.Companion")))
@interface SharedPlaylistItemDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaylistItemDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistItemsResponse")))
@interface SharedPlaylistItemsResponse : SharedBase
- (instancetype)initWithItems:(NSArray<SharedPlaylistItemDTO *> *)items __attribute__((swift_name("init(items:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaylistItemsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaylistItemsResponse *)doCopyItems:(NSArray<SharedPlaylistItemDTO *> *)items __attribute__((swift_name("doCopy(items:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedPlaylistItemDTO *> *items __attribute__((swift_name("items")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistItemsResponse.Companion")))
@interface SharedPlaylistItemsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaylistItemsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistsContainer")))
@interface SharedPlaylistsContainer : SharedBase
- (instancetype)initWithPlaylist:(NSArray<SharedPlaylistDTO *> * _Nullable)Playlist __attribute__((swift_name("init(Playlist:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaylistsContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaylistsContainer *)doCopyPlaylist:(NSArray<SharedPlaylistDTO *> * _Nullable)Playlist __attribute__((swift_name("doCopy(Playlist:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedPlaylistDTO *> * _Nullable Playlist __attribute__((swift_name("Playlist")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistsContainer.Companion")))
@interface SharedPlaylistsContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaylistsContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistsResponse")))
@interface SharedPlaylistsResponse : SharedBase
- (instancetype)initWithPlaylists:(NSArray<SharedPlaylistDTO *> * _Nullable)playlists MediaContainer:(SharedPlaylistsContainer * _Nullable)MediaContainer __attribute__((swift_name("init(playlists:MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedPlaylistsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedPlaylistsResponse *)doCopyPlaylists:(NSArray<SharedPlaylistDTO *> * _Nullable)playlists MediaContainer:(SharedPlaylistsContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(playlists:MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedPlaylistsContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@property (readonly) NSArray<SharedPlaylistDTO *> *allPlaylists __attribute__((swift_name("allPlaylists")));
@property (readonly) NSArray<SharedPlaylistDTO *> * _Nullable playlists __attribute__((swift_name("playlists")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistsResponse.Companion")))
@interface SharedPlaylistsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedPlaylistsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProfileDTO")))
@interface SharedProfileDTO : SharedBase
- (instancetype)initWithId:(int32_t)id uuid:(NSString *)uuid name:(NSString *)name avatar:(NSString * _Nullable)avatar thumb:(NSString * _Nullable)thumb isKid:(SharedBoolean * _Nullable)isKid hasPassword:(SharedBoolean * _Nullable)hasPassword restricted:(SharedBoolean * _Nullable)restricted admin:(SharedBoolean * _Nullable)admin guest:(SharedBoolean * _Nullable)guest protected:(SharedBoolean * _Nullable)protected_ __attribute__((swift_name("init(id:uuid:name:avatar:thumb:isKid:hasPassword:restricted:admin:guest:protected:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedProfileDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedProfileDTO *)doCopyId:(int32_t)id uuid:(NSString *)uuid name:(NSString *)name avatar:(NSString * _Nullable)avatar thumb:(NSString * _Nullable)thumb isKid:(SharedBoolean * _Nullable)isKid hasPassword:(SharedBoolean * _Nullable)hasPassword restricted:(SharedBoolean * _Nullable)restricted admin:(SharedBoolean * _Nullable)admin guest:(SharedBoolean * _Nullable)guest protected:(SharedBoolean * _Nullable)protected_ __attribute__((swift_name("doCopy(id:uuid:name:avatar:thumb:isKid:hasPassword:restricted:admin:guest:protected:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedProfile *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedBoolean * _Nullable admin __attribute__((swift_name("admin")));
@property (readonly) NSString * _Nullable avatar __attribute__((swift_name("avatar")));
@property (readonly) SharedBoolean * _Nullable guest __attribute__((swift_name("guest")));
@property (readonly) SharedBoolean * _Nullable hasPassword __attribute__((swift_name("hasPassword")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable isKid __attribute__((swift_name("isKid")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly, getter=protected) SharedBoolean * _Nullable protected_ __attribute__((swift_name("protected_")));
@property (readonly) SharedBoolean * _Nullable restricted __attribute__((swift_name("restricted")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProfileDTO.Companion")))
@interface SharedProfileDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedProfileDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProgramDTO")))
@interface SharedProgramDTO : SharedBase
- (instancetype)initWithId:(SharedStringOrInt * _Nullable)id title:(NSString * _Nullable)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description start:(NSString * _Nullable)start end:(NSString * _Nullable)end startTime:(SharedLong * _Nullable)startTime endTime:(SharedLong * _Nullable)endTime duration:(SharedInt * _Nullable)duration icon:(NSString * _Nullable)icon art:(NSString * _Nullable)art rating:(NSString * _Nullable)rating category:(NSString * _Nullable)category isNew:(SharedBoolean * _Nullable)isNew isLive:(SharedBoolean * _Nullable)isLive isPremiere:(SharedBoolean * _Nullable)isPremiere isFinale:(SharedBoolean * _Nullable)isFinale isSports:(SharedBoolean * _Nullable)isSports isKids:(SharedBoolean * _Nullable)isKids teams:(NSString * _Nullable)teams league:(NSString * _Nullable)league hasRecording:(SharedBoolean * _Nullable)hasRecording recordingId:(SharedStringOrInt * _Nullable)recordingId __attribute__((swift_name("init(id:title:subtitle:description:start:end:startTime:endTime:duration:icon:art:rating:category:isNew:isLive:isPremiere:isFinale:isSports:isKids:teams:league:hasRecording:recordingId:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedProgramDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedProgramDTO *)doCopyId:(SharedStringOrInt * _Nullable)id title:(NSString * _Nullable)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description start:(NSString * _Nullable)start end:(NSString * _Nullable)end startTime:(SharedLong * _Nullable)startTime endTime:(SharedLong * _Nullable)endTime duration:(SharedInt * _Nullable)duration icon:(NSString * _Nullable)icon art:(NSString * _Nullable)art rating:(NSString * _Nullable)rating category:(NSString * _Nullable)category isNew:(SharedBoolean * _Nullable)isNew isLive:(SharedBoolean * _Nullable)isLive isPremiere:(SharedBoolean * _Nullable)isPremiere isFinale:(SharedBoolean * _Nullable)isFinale isSports:(SharedBoolean * _Nullable)isSports isKids:(SharedBoolean * _Nullable)isKids teams:(NSString * _Nullable)teams league:(NSString * _Nullable)league hasRecording:(SharedBoolean * _Nullable)hasRecording recordingId:(SharedStringOrInt * _Nullable)recordingId __attribute__((swift_name("doCopy(id:title:subtitle:description:start:end:startTime:endTime:duration:icon:art:rating:category:isNew:isLive:isPremiere:isFinale:isSports:isKids:teams:league:hasRecording:recordingId:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedProgram *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) NSString * _Nullable category __attribute__((swift_name("category")));
@property (readonly) NSString * _Nullable description_ __attribute__((swift_name("description_")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable end __attribute__((swift_name("end")));
@property (readonly) SharedLong * _Nullable endDateMs __attribute__((swift_name("endDateMs")));
@property (readonly) SharedLong * _Nullable endTime __attribute__((swift_name("endTime")));
@property (readonly) SharedBoolean * _Nullable hasRecording __attribute__((swift_name("hasRecording")));
@property (readonly) NSString * _Nullable icon __attribute__((swift_name("icon")));
@property (readonly) SharedStringOrInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable isFinale __attribute__((swift_name("isFinale")));
@property (readonly) SharedBoolean * _Nullable isKids __attribute__((swift_name("isKids")));
@property (readonly) SharedBoolean * _Nullable isLive __attribute__((swift_name("isLive")));
@property (readonly) SharedBoolean * _Nullable isNew __attribute__((swift_name("isNew")));
@property (readonly) SharedBoolean * _Nullable isPremiere __attribute__((swift_name("isPremiere")));
@property (readonly) SharedBoolean * _Nullable isSports __attribute__((swift_name("isSports")));
@property (readonly) NSString * _Nullable league __attribute__((swift_name("league")));
@property (readonly) NSString * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) SharedStringOrInt * _Nullable recordingId __attribute__((swift_name("recordingId")));
@property (readonly) NSString *safeId __attribute__((swift_name("safeId")));
@property (readonly) NSString *safeTitle __attribute__((swift_name("safeTitle")));
@property (readonly) NSString * _Nullable start __attribute__((swift_name("start")));
@property (readonly) SharedLong * _Nullable startDateMs __attribute__((swift_name("startDateMs")));
@property (readonly) SharedLong * _Nullable startTime __attribute__((swift_name("startTime")));
@property (readonly) NSString * _Nullable subtitle __attribute__((swift_name("subtitle")));
@property (readonly) NSString * _Nullable teams __attribute__((swift_name("teams")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ProgramDTO.Companion")))
@interface SharedProgramDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedProgramDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingDTO")))
@interface SharedRecordingDTO : SharedBase
- (instancetype)initWithId:(SharedStringOrInt * _Nullable)id title:(NSString * _Nullable)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art channelId:(SharedStringOrInt * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo startTime:(NSString * _Nullable)startTime endTime:(NSString * _Nullable)endTime duration:(SharedInt * _Nullable)duration status:(NSString * _Nullable)status filePath:(NSString * _Nullable)filePath fileSize:(SharedInt * _Nullable)fileSize seasonNumber:(SharedInt * _Nullable)seasonNumber episodeNumber:(SharedInt * _Nullable)episodeNumber seriesRecord:(SharedBoolean * _Nullable)seriesRecord seriesRuleId:(SharedInt * _Nullable)seriesRuleId genres:(NSString * _Nullable)genres contentRating:(NSString * _Nullable)contentRating year:(SharedInt * _Nullable)year rating:(SharedDouble * _Nullable)rating isMovie:(SharedBoolean * _Nullable)isMovie viewOffset:(SharedInt * _Nullable)viewOffset commercials:(NSArray<SharedCommercialDTO *> * _Nullable)commercials priority:(SharedInt * _Nullable)priority programId:(SharedStringOrInt * _Nullable)programId seriesId:(SharedStringOrInt * _Nullable)seriesId category:(NSString * _Nullable)category createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("init(id:title:subtitle:description:summary:thumb:art:channelId:channelName:channelLogo:startTime:endTime:duration:status:filePath:fileSize:seasonNumber:episodeNumber:seriesRecord:seriesRuleId:genres:contentRating:year:rating:isMovie:viewOffset:commercials:priority:programId:seriesId:category:createdAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedRecordingDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedRecordingDTO *)doCopyId:(SharedStringOrInt * _Nullable)id title:(NSString * _Nullable)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art channelId:(SharedStringOrInt * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo startTime:(NSString * _Nullable)startTime endTime:(NSString * _Nullable)endTime duration:(SharedInt * _Nullable)duration status:(NSString * _Nullable)status filePath:(NSString * _Nullable)filePath fileSize:(SharedInt * _Nullable)fileSize seasonNumber:(SharedInt * _Nullable)seasonNumber episodeNumber:(SharedInt * _Nullable)episodeNumber seriesRecord:(SharedBoolean * _Nullable)seriesRecord seriesRuleId:(SharedInt * _Nullable)seriesRuleId genres:(NSString * _Nullable)genres contentRating:(NSString * _Nullable)contentRating year:(SharedInt * _Nullable)year rating:(SharedDouble * _Nullable)rating isMovie:(SharedBoolean * _Nullable)isMovie viewOffset:(SharedInt * _Nullable)viewOffset commercials:(NSArray<SharedCommercialDTO *> * _Nullable)commercials priority:(SharedInt * _Nullable)priority programId:(SharedStringOrInt * _Nullable)programId seriesId:(SharedStringOrInt * _Nullable)seriesId category:(NSString * _Nullable)category createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("doCopy(id:title:subtitle:description:summary:thumb:art:channelId:channelName:channelLogo:startTime:endTime:duration:status:filePath:fileSize:seasonNumber:episodeNumber:seriesRecord:seriesRuleId:genres:contentRating:year:rating:isMovie:viewOffset:commercials:priority:programId:seriesId:category:createdAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedRecording *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) NSString * _Nullable category __attribute__((swift_name("category")));
@property (readonly) SharedStringOrInt * _Nullable channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelLogo __attribute__((swift_name("channelLogo")));
@property (readonly) NSString * _Nullable channelName __attribute__((swift_name("channelName")));
@property (readonly) NSArray<SharedCommercialDTO *> * _Nullable commercials __attribute__((swift_name("commercials")));
@property (readonly) NSString * _Nullable contentRating __attribute__((swift_name("contentRating")));
@property (readonly) NSString * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) NSString * _Nullable description_ __attribute__((swift_name("description_")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable endTime __attribute__((swift_name("endTime")));
@property (readonly) SharedInt * _Nullable episodeNumber __attribute__((swift_name("episodeNumber")));
@property (readonly) NSString * _Nullable filePath __attribute__((swift_name("filePath")));
@property (readonly) SharedInt * _Nullable fileSize __attribute__((swift_name("fileSize")));
@property (readonly) NSString * _Nullable genres __attribute__((swift_name("genres")));
@property (readonly) SharedStringOrInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable isMovie __attribute__((swift_name("isMovie")));
@property (readonly) SharedInt * _Nullable priority __attribute__((swift_name("priority")));
@property (readonly) SharedStringOrInt * _Nullable programId __attribute__((swift_name("programId")));
@property (readonly) SharedDouble * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) int32_t safeId __attribute__((swift_name("safeId")));
@property (readonly) NSString *safeStatus __attribute__((swift_name("safeStatus")));
@property (readonly) NSString *safeTitle __attribute__((swift_name("safeTitle")));
@property (readonly) SharedInt * _Nullable seasonNumber __attribute__((swift_name("seasonNumber")));
@property (readonly) SharedStringOrInt * _Nullable seriesId __attribute__((swift_name("seriesId")));
@property (readonly) SharedBoolean * _Nullable seriesRecord __attribute__((swift_name("seriesRecord")));
@property (readonly) SharedInt * _Nullable seriesRuleId __attribute__((swift_name("seriesRuleId")));
@property (readonly) NSString * _Nullable startTime __attribute__((swift_name("startTime")));
@property (readonly) NSString * _Nullable status __attribute__((swift_name("status")));
@property (readonly) NSString * _Nullable subtitle __attribute__((swift_name("subtitle")));
@property (readonly) NSString * _Nullable summary __attribute__((swift_name("summary")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@property (readonly) SharedInt * _Nullable viewOffset __attribute__((swift_name("viewOffset")));
@property (readonly) SharedInt * _Nullable year __attribute__((swift_name("year")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingDTO.Companion")))
@interface SharedRecordingDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRecordingDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStatsResponse")))
@interface SharedRecordingStatsResponse : SharedBase
- (instancetype)initWithTotal:(int32_t)total scheduled:(int32_t)scheduled recording:(int32_t)recording completed:(int32_t)completed failed:(int32_t)failed totalSize:(SharedInt * _Nullable)totalSize __attribute__((swift_name("init(total:scheduled:recording:completed:failed:totalSize:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedRecordingStatsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedRecordingStatsResponse *)doCopyTotal:(int32_t)total scheduled:(int32_t)scheduled recording:(int32_t)recording completed:(int32_t)completed failed:(int32_t)failed totalSize:(SharedInt * _Nullable)totalSize __attribute__((swift_name("doCopy(total:scheduled:recording:completed:failed:totalSize:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t completed __attribute__((swift_name("completed")));
@property (readonly) int32_t failed __attribute__((swift_name("failed")));
@property (readonly) int32_t recording __attribute__((swift_name("recording")));
@property (readonly) int32_t scheduled __attribute__((swift_name("scheduled")));
@property (readonly) int32_t total __attribute__((swift_name("total")));
@property (readonly) SharedInt * _Nullable totalSize __attribute__((swift_name("totalSize")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStatsResponse.Companion")))
@interface SharedRecordingStatsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRecordingStatsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStreamResponse")))
@interface SharedRecordingStreamResponse : SharedBase
- (instancetype)initWithUrl:(NSString *)url format:(NSString * _Nullable)format __attribute__((swift_name("init(url:format:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedRecordingStreamResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedRecordingStreamResponse *)doCopyUrl:(NSString *)url format:(NSString * _Nullable)format __attribute__((swift_name("doCopy(url:format:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable format __attribute__((swift_name("format")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStreamResponse.Companion")))
@interface SharedRecordingStreamResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRecordingStreamResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingsResponse")))
@interface SharedRecordingsResponse : SharedBase
- (instancetype)initWithRecordings:(NSArray<SharedRecordingDTO *> * _Nullable)recordings __attribute__((swift_name("init(recordings:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedRecordingsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedRecordingsResponse *)doCopyRecordings:(NSArray<SharedRecordingDTO *> * _Nullable)recordings __attribute__((swift_name("doCopy(recordings:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedRecordingDTO *> *allRecordings __attribute__((swift_name("allRecordings")));
@property (readonly) NSArray<SharedRecordingDTO *> * _Nullable recordings __attribute__((swift_name("recordings")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingsResponse.Companion")))
@interface SharedRecordingsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRecordingsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoleDTO")))
@interface SharedRoleDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id tag:(NSString *)tag role:(NSString * _Nullable)role thumb:(NSString * _Nullable)thumb __attribute__((swift_name("init(id:tag:role:thumb:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedRoleDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedRoleDTO *)doCopyId:(SharedInt * _Nullable)id tag:(NSString *)tag role:(NSString * _Nullable)role thumb:(NSString * _Nullable)thumb __attribute__((swift_name("doCopy(id:tag:role:thumb:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable role __attribute__((swift_name("role")));
@property (readonly) NSString *tag __attribute__((swift_name("tag")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RoleDTO.Companion")))
@interface SharedRoleDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRoleDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ScheduledRecordingsResponse")))
@interface SharedScheduledRecordingsResponse : SharedBase
- (instancetype)initWithScheduled:(NSArray<SharedRecordingDTO *> * _Nullable)scheduled __attribute__((swift_name("init(scheduled:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedScheduledRecordingsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedScheduledRecordingsResponse *)doCopyScheduled:(NSArray<SharedRecordingDTO *> * _Nullable)scheduled __attribute__((swift_name("doCopy(scheduled:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedRecordingDTO *> *allScheduled __attribute__((swift_name("allScheduled")));
@property (readonly) NSArray<SharedRecordingDTO *> * _Nullable scheduled __attribute__((swift_name("scheduled")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ScheduledRecordingsResponse.Companion")))
@interface SharedScheduledRecordingsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedScheduledRecordingsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchContainer")))
@interface SharedSearchContainer : SharedBase
- (instancetype)initWithHub:(NSArray<SharedSearchHubDTO *> * _Nullable)Hub __attribute__((swift_name("init(Hub:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSearchContainerCompanion *companion __attribute__((swift_name("companion")));
- (SharedSearchContainer *)doCopyHub:(NSArray<SharedSearchHubDTO *> * _Nullable)Hub __attribute__((swift_name("doCopy(Hub:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedSearchHubDTO *> * _Nullable Hub __attribute__((swift_name("Hub")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchContainer.Companion")))
@interface SharedSearchContainerCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSearchContainerCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchHubDTO")))
@interface SharedSearchHubDTO : SharedBase
- (instancetype)initWithType:(NSString * _Nullable)type title:(NSString * _Nullable)title size:(SharedInt * _Nullable)size Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata __attribute__((swift_name("init(type:title:size:Metadata:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSearchHubDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedSearchHubDTO *)doCopyType:(NSString * _Nullable)type title:(NSString * _Nullable)title size:(SharedInt * _Nullable)size Metadata:(NSArray<SharedMediaItemDTO *> * _Nullable)Metadata __attribute__((swift_name("doCopy(type:title:size:Metadata:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedMediaItemDTO *> * _Nullable Metadata __attribute__((swift_name("Metadata")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable type __attribute__((swift_name("type")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchHubDTO.Companion")))
@interface SharedSearchHubDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSearchHubDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchResponse")))
@interface SharedSearchResponse : SharedBase
- (instancetype)initWithMediaContainer:(SharedSearchContainer * _Nullable)MediaContainer __attribute__((swift_name("init(MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSearchResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedSearchResponse *)doCopyMediaContainer:(SharedSearchContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedSearchContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SearchResponse.Companion")))
@interface SharedSearchResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSearchResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SeriesRuleDTO")))
@interface SharedSeriesRuleDTO : SharedBase
- (instancetype)initWithId:(SharedStringOrInt *)id title:(NSString * _Nullable)title channelId:(SharedStringOrInt * _Nullable)channelId enabled:(SharedBoolean * _Nullable)enabled prePadding:(SharedInt * _Nullable)prePadding postPadding:(SharedInt * _Nullable)postPadding keepCount:(SharedInt * _Nullable)keepCount recordingCount:(SharedInt * _Nullable)recordingCount __attribute__((swift_name("init(id:title:channelId:enabled:prePadding:postPadding:keepCount:recordingCount:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSeriesRuleDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedSeriesRuleDTO *)doCopyId:(SharedStringOrInt *)id title:(NSString * _Nullable)title channelId:(SharedStringOrInt * _Nullable)channelId enabled:(SharedBoolean * _Nullable)enabled prePadding:(SharedInt * _Nullable)prePadding postPadding:(SharedInt * _Nullable)postPadding keepCount:(SharedInt * _Nullable)keepCount recordingCount:(SharedInt * _Nullable)recordingCount __attribute__((swift_name("doCopy(id:title:channelId:enabled:prePadding:postPadding:keepCount:recordingCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedSeriesRule *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedStringOrInt * _Nullable channelId __attribute__((swift_name("channelId")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) SharedStringOrInt *id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable keepCount __attribute__((swift_name("keepCount")));
@property (readonly) SharedInt * _Nullable postPadding __attribute__((swift_name("postPadding")));
@property (readonly) SharedInt * _Nullable prePadding __attribute__((swift_name("prePadding")));
@property (readonly) SharedInt * _Nullable recordingCount __attribute__((swift_name("recordingCount")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SeriesRuleDTO.Companion")))
@interface SharedSeriesRuleDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSeriesRuleDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SeriesRulesResponse")))
@interface SharedSeriesRulesResponse : SharedBase
- (instancetype)initWithRules:(NSArray<SharedSeriesRuleDTO *> *)rules __attribute__((swift_name("init(rules:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSeriesRulesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedSeriesRulesResponse *)doCopyRules:(NSArray<SharedSeriesRuleDTO *> *)rules __attribute__((swift_name("doCopy(rules:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedSeriesRuleDTO *> *rules __attribute__((swift_name("rules")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SeriesRulesResponse.Companion")))
@interface SharedSeriesRulesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSeriesRulesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerCapabilitiesDTO")))
@interface SharedServerCapabilitiesDTO : SharedBase
- (instancetype)initWithLiveTV:(SharedBoolean * _Nullable)liveTV dvr:(SharedBoolean * _Nullable)dvr transcoding:(SharedBoolean * _Nullable)transcoding offlineDownloads:(SharedBoolean * _Nullable)offlineDownloads multiUser:(SharedBoolean * _Nullable)multiUser watchParty:(SharedBoolean * _Nullable)watchParty epgSources:(NSArray<NSString *> * _Nullable)epgSources __attribute__((swift_name("init(liveTV:dvr:transcoding:offlineDownloads:multiUser:watchParty:epgSources:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedServerCapabilitiesDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedServerCapabilitiesDTO *)doCopyLiveTV:(SharedBoolean * _Nullable)liveTV dvr:(SharedBoolean * _Nullable)dvr transcoding:(SharedBoolean * _Nullable)transcoding offlineDownloads:(SharedBoolean * _Nullable)offlineDownloads multiUser:(SharedBoolean * _Nullable)multiUser watchParty:(SharedBoolean * _Nullable)watchParty epgSources:(NSArray<NSString *> * _Nullable)epgSources __attribute__((swift_name("doCopy(liveTV:dvr:transcoding:offlineDownloads:multiUser:watchParty:epgSources:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedServerCapabilities *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedBoolean * _Nullable dvr __attribute__((swift_name("dvr")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="epg_sources")
*/
@property (readonly) NSArray<NSString *> * _Nullable epgSources __attribute__((swift_name("epgSources")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="live_tv")
*/
@property (readonly) SharedBoolean * _Nullable liveTV __attribute__((swift_name("liveTV")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="multi_user")
*/
@property (readonly) SharedBoolean * _Nullable multiUser __attribute__((swift_name("multiUser")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="offline_downloads")
*/
@property (readonly) SharedBoolean * _Nullable offlineDownloads __attribute__((swift_name("offlineDownloads")));
@property (readonly) SharedBoolean * _Nullable transcoding __attribute__((swift_name("transcoding")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="watch_party")
*/
@property (readonly) SharedBoolean * _Nullable watchParty __attribute__((swift_name("watchParty")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerCapabilitiesDTO.Companion")))
@interface SharedServerCapabilitiesDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedServerCapabilitiesDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerInfoDTO")))
@interface SharedServerInfoDTO : SharedBase
- (instancetype)initWithName:(NSString * _Nullable)name version:(NSString * _Nullable)version platform:(NSString * _Nullable)platform machineIdentifier:(NSString * _Nullable)machineIdentifier owner:(SharedBoolean * _Nullable)owner transcoderActive:(SharedBoolean * _Nullable)transcoderActive __attribute__((swift_name("init(name:version:platform:machineIdentifier:owner:transcoderActive:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedServerInfoDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedServerInfoDTO *)doCopyName:(NSString * _Nullable)name version:(NSString * _Nullable)version platform:(NSString * _Nullable)platform machineIdentifier:(NSString * _Nullable)machineIdentifier owner:(SharedBoolean * _Nullable)owner transcoderActive:(SharedBoolean * _Nullable)transcoderActive __attribute__((swift_name("doCopy(name:version:platform:machineIdentifier:owner:transcoderActive:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedServerInfo *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable machineIdentifier __attribute__((swift_name("machineIdentifier")));
@property (readonly) NSString * _Nullable name __attribute__((swift_name("name")));
@property (readonly) SharedBoolean * _Nullable owner __attribute__((swift_name("owner")));
@property (readonly) NSString * _Nullable platform __attribute__((swift_name("platform")));

/**
 * @note annotations
 *   kotlinx.serialization.SerialName(value="transcoder_active")
*/
@property (readonly) SharedBoolean * _Nullable transcoderActive __attribute__((swift_name("transcoderActive")));
@property (readonly) NSString * _Nullable version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerInfoDTO.Companion")))
@interface SharedServerInfoDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedServerInfoDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StreamDTO")))
@interface SharedStreamDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id streamType:(SharedInt * _Nullable)streamType codec:(NSString * _Nullable)codec index:(SharedInt * _Nullable)index language:(NSString * _Nullable)language languageCode:(NSString * _Nullable)languageCode displayTitle:(NSString * _Nullable)displayTitle selected:(SharedBoolean * _Nullable)selected forced:(SharedBoolean * _Nullable)forced default:(SharedBoolean * _Nullable)default_ title:(NSString * _Nullable)title width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height bitrate:(SharedInt * _Nullable)bitrate frameRate:(SharedDouble * _Nullable)frameRate channels:(SharedInt * _Nullable)channels samplingRate:(SharedInt * _Nullable)samplingRate __attribute__((swift_name("init(id:streamType:codec:index:language:languageCode:displayTitle:selected:forced:default:title:width:height:bitrate:frameRate:channels:samplingRate:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedStreamDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedStreamDTO *)doCopyId:(SharedInt * _Nullable)id streamType:(SharedInt * _Nullable)streamType codec:(NSString * _Nullable)codec index:(SharedInt * _Nullable)index language:(NSString * _Nullable)language languageCode:(NSString * _Nullable)languageCode displayTitle:(NSString * _Nullable)displayTitle selected:(SharedBoolean * _Nullable)selected forced:(SharedBoolean * _Nullable)forced default:(SharedBoolean * _Nullable)default_ title:(NSString * _Nullable)title width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height bitrate:(SharedInt * _Nullable)bitrate frameRate:(SharedDouble * _Nullable)frameRate channels:(SharedInt * _Nullable)channels samplingRate:(SharedInt * _Nullable)samplingRate __attribute__((swift_name("doCopy(id:streamType:codec:index:language:languageCode:displayTitle:selected:forced:default:title:width:height:bitrate:frameRate:channels:samplingRate:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedMediaStream *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable bitrate __attribute__((swift_name("bitrate")));
@property (readonly) SharedInt * _Nullable channels __attribute__((swift_name("channels")));
@property (readonly) NSString * _Nullable codec __attribute__((swift_name("codec")));
@property (readonly, getter=default) SharedBoolean * _Nullable default_ __attribute__((swift_name("default_")));
@property (readonly) NSString * _Nullable displayTitle __attribute__((swift_name("displayTitle")));
@property (readonly) SharedBoolean * _Nullable forced __attribute__((swift_name("forced")));
@property (readonly) SharedDouble * _Nullable frameRate __attribute__((swift_name("frameRate")));
@property (readonly) SharedInt * _Nullable height __attribute__((swift_name("height")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable index __attribute__((swift_name("index")));
@property (readonly) NSString * _Nullable language __attribute__((swift_name("language")));
@property (readonly) NSString * _Nullable languageCode __attribute__((swift_name("languageCode")));
@property (readonly) SharedInt * _Nullable samplingRate __attribute__((swift_name("samplingRate")));
@property (readonly) SharedBoolean * _Nullable selected __attribute__((swift_name("selected")));
@property (readonly) SharedInt * _Nullable streamType __attribute__((swift_name("streamType")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) SharedInt * _Nullable width __attribute__((swift_name("width")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StreamDTO.Companion")))
@interface SharedStreamDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedStreamDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable(with=NormalClass(value=com/openflix/data/dto/StringOrIntSerializer))
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StringOrInt")))
@interface SharedStringOrInt : SharedBase
- (instancetype)initWithStringValue:(NSString *)stringValue intValue:(int32_t)intValue __attribute__((swift_name("init(stringValue:intValue:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedStringOrIntCompanion *companion __attribute__((swift_name("companion")));
- (SharedStringOrInt *)doCopyStringValue:(NSString *)stringValue intValue:(int32_t)intValue __attribute__((swift_name("doCopy(stringValue:intValue:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t intValue __attribute__((swift_name("intValue")));
@property (readonly) NSString *stringValue __attribute__((swift_name("stringValue")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StringOrInt.Companion")))
@interface SharedStringOrIntCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedStringOrIntCompanion *shared __attribute__((swift_name("shared")));
- (SharedStringOrInt *)fromIntValue:(int32_t)value __attribute__((swift_name("fromInt(value:)")));
- (SharedStringOrInt *)fromStringValue:(NSString *)value __attribute__((swift_name("fromString(value:)")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializationStrategy")))
@protocol SharedKotlinx_serialization_coreSerializationStrategy
@required
- (void)serializeEncoder:(id<SharedKotlinx_serialization_coreEncoder>)encoder value:(id _Nullable)value __attribute__((swift_name("serialize(encoder:value:)")));
@property (readonly) id<SharedKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDeserializationStrategy")))
@protocol SharedKotlinx_serialization_coreDeserializationStrategy
@required
- (id _Nullable)deserializeDecoder:(id<SharedKotlinx_serialization_coreDecoder>)decoder __attribute__((swift_name("deserialize(decoder:)")));
@property (readonly) id<SharedKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreKSerializer")))
@protocol SharedKotlinx_serialization_coreKSerializer <SharedKotlinx_serialization_coreSerializationStrategy, SharedKotlinx_serialization_coreDeserializationStrategy>
@required
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StringOrIntSerializer")))
@interface SharedStringOrIntSerializer : SharedBase <SharedKotlinx_serialization_coreKSerializer>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)stringOrIntSerializer __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedStringOrIntSerializer *shared __attribute__((swift_name("shared")));
- (SharedStringOrInt *)deserializeDecoder:(id<SharedKotlinx_serialization_coreDecoder>)decoder __attribute__((swift_name("deserialize(decoder:)")));
- (void)serializeEncoder:(id<SharedKotlinx_serialization_coreEncoder>)encoder value:(SharedStringOrInt *)value __attribute__((swift_name("serialize(encoder:value:)")));
@property (readonly) id<SharedKotlinx_serialization_coreSerialDescriptor> descriptor __attribute__((swift_name("descriptor")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SwitchProfileResponse")))
@interface SharedSwitchProfileResponse : SharedBase
- (instancetype)initWithAuthToken:(NSString * _Nullable)authToken token:(NSString * _Nullable)token success:(SharedBoolean * _Nullable)success message:(NSString * _Nullable)message __attribute__((swift_name("init(authToken:token:success:message:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedSwitchProfileResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedSwitchProfileResponse *)doCopyAuthToken:(NSString * _Nullable)authToken token:(NSString * _Nullable)token success:(SharedBoolean * _Nullable)success message:(NSString * _Nullable)message __attribute__((swift_name("doCopy(authToken:token:success:message:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable authToken __attribute__((swift_name("authToken")));
@property (readonly) NSString * _Nullable message __attribute__((swift_name("message")));
@property (readonly) SharedBoolean * _Nullable success __attribute__((swift_name("success")));
@property (readonly) NSString * _Nullable token __attribute__((swift_name("token")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SwitchProfileResponse.Companion")))
@interface SharedSwitchProfileResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedSwitchProfileResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamDTO")))
@interface SharedTeamDTO : SharedBase
- (instancetype)initWithName:(NSString *)name aliases:(NSArray<NSString *> * _Nullable)aliases logo:(NSString * _Nullable)logo __attribute__((swift_name("init(name:aliases:logo:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedTeamDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedTeamDTO *)doCopyName:(NSString *)name aliases:(NSArray<NSString *> * _Nullable)aliases logo:(NSString * _Nullable)logo __attribute__((swift_name("doCopy(name:aliases:logo:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedTeam *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<NSString *> * _Nullable aliases __attribute__((swift_name("aliases")));
@property (readonly) NSString * _Nullable logo __attribute__((swift_name("logo")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamDTO.Companion")))
@interface SharedTeamDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedTeamDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamPassDTO")))
@interface SharedTeamPassDTO : SharedBase
- (instancetype)initWithId:(int32_t)id userId:(SharedInt * _Nullable)userId teamName:(NSString *)teamName teamAliases:(NSString * _Nullable)teamAliases league:(NSString *)league channelIds:(NSString * _Nullable)channelIds prePadding:(SharedInt * _Nullable)prePadding postPadding:(SharedInt * _Nullable)postPadding keepCount:(SharedInt * _Nullable)keepCount priority:(SharedInt * _Nullable)priority enabled:(SharedBoolean * _Nullable)enabled upcomingCount:(SharedInt * _Nullable)upcomingCount logoUrl:(NSString * _Nullable)logoUrl __attribute__((swift_name("init(id:userId:teamName:teamAliases:league:channelIds:prePadding:postPadding:keepCount:priority:enabled:upcomingCount:logoUrl:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedTeamPassDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedTeamPassDTO *)doCopyId:(int32_t)id userId:(SharedInt * _Nullable)userId teamName:(NSString *)teamName teamAliases:(NSString * _Nullable)teamAliases league:(NSString *)league channelIds:(NSString * _Nullable)channelIds prePadding:(SharedInt * _Nullable)prePadding postPadding:(SharedInt * _Nullable)postPadding keepCount:(SharedInt * _Nullable)keepCount priority:(SharedInt * _Nullable)priority enabled:(SharedBoolean * _Nullable)enabled upcomingCount:(SharedInt * _Nullable)upcomingCount logoUrl:(NSString * _Nullable)logoUrl __attribute__((swift_name("doCopy(id:userId:teamName:teamAliases:league:channelIds:prePadding:postPadding:keepCount:priority:enabled:upcomingCount:logoUrl:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedTeamPass *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable channelIds __attribute__((swift_name("channelIds")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable keepCount __attribute__((swift_name("keepCount")));
@property (readonly) NSString *league __attribute__((swift_name("league")));
@property (readonly) NSString * _Nullable logoUrl __attribute__((swift_name("logoUrl")));
@property (readonly) SharedInt * _Nullable postPadding __attribute__((swift_name("postPadding")));
@property (readonly) SharedInt * _Nullable prePadding __attribute__((swift_name("prePadding")));
@property (readonly) SharedInt * _Nullable priority __attribute__((swift_name("priority")));
@property (readonly) NSString * _Nullable teamAliases __attribute__((swift_name("teamAliases")));
@property (readonly) NSString *teamName __attribute__((swift_name("teamName")));
@property (readonly) SharedInt * _Nullable upcomingCount __attribute__((swift_name("upcomingCount")));
@property (readonly) SharedInt * _Nullable userId __attribute__((swift_name("userId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamPassDTO.Companion")))
@interface SharedTeamPassDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedTeamPassDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamPassesResponse")))
@interface SharedTeamPassesResponse : SharedBase
- (instancetype)initWithTeamPasses:(NSArray<SharedTeamPassDTO *> *)teamPasses __attribute__((swift_name("init(teamPasses:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedTeamPassesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedTeamPassesResponse *)doCopyTeamPasses:(NSArray<SharedTeamPassDTO *> *)teamPasses __attribute__((swift_name("doCopy(teamPasses:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedTeamPassDTO *> *teamPasses __attribute__((swift_name("teamPasses")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamPassesResponse.Companion")))
@interface SharedTeamPassesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedTeamPassesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamsResponse")))
@interface SharedTeamsResponse : SharedBase
- (instancetype)initWithTeams:(NSArray<SharedTeamDTO *> *)teams __attribute__((swift_name("init(teams:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedTeamsResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedTeamsResponse *)doCopyTeams:(NSArray<SharedTeamDTO *> *)teams __attribute__((swift_name("doCopy(teams:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedTeamDTO *> *teams __attribute__((swift_name("teams")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamsResponse.Companion")))
@interface SharedTeamsResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedTeamsResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("UserDTO")))
@interface SharedUserDTO : SharedBase
- (instancetype)initWithId:(int32_t)id uuid:(NSString * _Nullable)uuid username:(NSString *)username email:(NSString * _Nullable)email title:(NSString * _Nullable)title thumb:(NSString * _Nullable)thumb admin:(SharedBoolean * _Nullable)admin createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("init(id:uuid:username:email:title:thumb:admin:createdAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedUserDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedUserDTO *)doCopyId:(int32_t)id uuid:(NSString * _Nullable)uuid username:(NSString *)username email:(NSString * _Nullable)email title:(NSString * _Nullable)title thumb:(NSString * _Nullable)thumb admin:(SharedBoolean * _Nullable)admin createdAt:(NSString * _Nullable)createdAt updatedAt:(NSString * _Nullable)updatedAt __attribute__((swift_name("doCopy(id:uuid:username:email:title:thumb:admin:createdAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedUser *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedBoolean * _Nullable admin __attribute__((swift_name("admin")));
@property (readonly) NSString * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) NSString * _Nullable email __attribute__((swift_name("email")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) NSString * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@property (readonly) NSString *username __attribute__((swift_name("username")));
@property (readonly) NSString * _Nullable uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("UserDTO.Companion")))
@interface SharedUserDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedUserDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistItemDTO")))
@interface SharedWatchlistItemDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id mediaId:(SharedInt * _Nullable)mediaId addedAt:(NSString * _Nullable)addedAt media:(SharedMediaItemDTO * _Nullable)media __attribute__((swift_name("init(id:mediaId:addedAt:media:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedWatchlistItemDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedWatchlistItemDTO *)doCopyId:(SharedInt * _Nullable)id mediaId:(SharedInt * _Nullable)mediaId addedAt:(NSString * _Nullable)addedAt media:(SharedMediaItemDTO * _Nullable)media __attribute__((swift_name("doCopy(id:mediaId:addedAt:media:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedWatchlistItem *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) SharedMediaItemDTO * _Nullable media __attribute__((swift_name("media")));
@property (readonly) SharedInt * _Nullable mediaId __attribute__((swift_name("mediaId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistItemDTO.Companion")))
@interface SharedWatchlistItemDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedWatchlistItemDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistResponse")))
@interface SharedWatchlistResponse : SharedBase
- (instancetype)initWithItems:(NSArray<SharedWatchlistItemDTO *> * _Nullable)items MediaContainer:(SharedMediaContainer * _Nullable)MediaContainer __attribute__((swift_name("init(items:MediaContainer:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedWatchlistResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedWatchlistResponse *)doCopyItems:(NSArray<SharedWatchlistItemDTO *> * _Nullable)items MediaContainer:(SharedMediaContainer * _Nullable)MediaContainer __attribute__((swift_name("doCopy(items:MediaContainer:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedMediaContainer * _Nullable MediaContainer __attribute__((swift_name("MediaContainer")));
@property (readonly) NSArray<SharedWatchlistItemDTO *> *allItems __attribute__((swift_name("allItems")));
@property (readonly) NSArray<SharedWatchlistItemDTO *> * _Nullable items __attribute__((swift_name("items")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistResponse.Companion")))
@interface SharedWatchlistResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedWatchlistResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WriterDTO")))
@interface SharedWriterDTO : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("init(id:tag:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedWriterDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedWriterDTO *)doCopyId:(SharedInt * _Nullable)id tag:(NSString *)tag __attribute__((swift_name("doCopy(id:tag:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString *tag __attribute__((swift_name("tag")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WriterDTO.Companion")))
@interface SharedWriterDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedWriterDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XtreamSourceDTO")))
@interface SharedXtreamSourceDTO : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name serverUrl:(NSString *)serverUrl username:(NSString *)username enabled:(SharedBoolean * _Nullable)enabled importLive:(SharedBoolean * _Nullable)importLive importVod:(SharedBoolean * _Nullable)importVod importSeries:(SharedBoolean * _Nullable)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(SharedInt * _Nullable)channelCount vodCount:(SharedInt * _Nullable)vodCount seriesCount:(SharedInt * _Nullable)seriesCount lastFetched:(NSString * _Nullable)lastFetched expirationDate:(NSString * _Nullable)expirationDate createdAt:(NSString * _Nullable)createdAt __attribute__((swift_name("init(id:name:serverUrl:username:enabled:importLive:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:vodCount:seriesCount:lastFetched:expirationDate:createdAt:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedXtreamSourceDTOCompanion *companion __attribute__((swift_name("companion")));
- (SharedXtreamSourceDTO *)doCopyId:(int32_t)id name:(NSString *)name serverUrl:(NSString *)serverUrl username:(NSString *)username enabled:(SharedBoolean * _Nullable)enabled importLive:(SharedBoolean * _Nullable)importLive importVod:(SharedBoolean * _Nullable)importVod importSeries:(SharedBoolean * _Nullable)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(SharedInt * _Nullable)channelCount vodCount:(SharedInt * _Nullable)vodCount seriesCount:(SharedInt * _Nullable)seriesCount lastFetched:(NSString * _Nullable)lastFetched expirationDate:(NSString * _Nullable)expirationDate createdAt:(NSString * _Nullable)createdAt __attribute__((swift_name("doCopy(id:name:serverUrl:username:enabled:importLive:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:vodCount:seriesCount:lastFetched:expirationDate:createdAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedXtreamSource *)toDomain __attribute__((swift_name("toDomain()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable channelCount __attribute__((swift_name("channelCount")));
@property (readonly) NSString * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) SharedBoolean * _Nullable enabled __attribute__((swift_name("enabled")));
@property (readonly) NSString * _Nullable expirationDate __attribute__((swift_name("expirationDate")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedBoolean * _Nullable importLive __attribute__((swift_name("importLive")));
@property (readonly) SharedBoolean * _Nullable importSeries __attribute__((swift_name("importSeries")));
@property (readonly) SharedBoolean * _Nullable importVod __attribute__((swift_name("importVod")));
@property (readonly) NSString * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) SharedInt * _Nullable seriesCount __attribute__((swift_name("seriesCount")));
@property (readonly) SharedInt * _Nullable seriesLibraryId __attribute__((swift_name("seriesLibraryId")));
@property (readonly) NSString *serverUrl __attribute__((swift_name("serverUrl")));
@property (readonly) NSString *username __attribute__((swift_name("username")));
@property (readonly) SharedInt * _Nullable vodCount __attribute__((swift_name("vodCount")));
@property (readonly) SharedInt * _Nullable vodLibraryId __attribute__((swift_name("vodLibraryId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XtreamSourceDTO.Companion")))
@interface SharedXtreamSourceDTOCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedXtreamSourceDTOCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.Serializable
*/
__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XtreamSourcesResponse")))
@interface SharedXtreamSourcesResponse : SharedBase
- (instancetype)initWithSources:(NSArray<SharedXtreamSourceDTO *> *)sources __attribute__((swift_name("init(sources:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedXtreamSourcesResponseCompanion *companion __attribute__((swift_name("companion")));
- (SharedXtreamSourcesResponse *)doCopySources:(NSArray<SharedXtreamSourceDTO *> *)sources __attribute__((swift_name("doCopy(sources:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<SharedXtreamSourceDTO *> *sources __attribute__((swift_name("sources")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XtreamSourcesResponse.Companion")))
@interface SharedXtreamSourcesResponseCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedXtreamSourcesResponseCompanion *shared __attribute__((swift_name("shared")));
- (id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("serializer()")));
@end

__attribute__((swift_name("KotlinThrowable")))
@interface SharedKotlinThrowable : SharedBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));

/**
 * @note annotations
 *   kotlin.experimental.ExperimentalNativeApi
*/
- (SharedKotlinArray<NSString *> *)getStackTrace __attribute__((swift_name("getStackTrace()")));
- (void)printStackTrace __attribute__((swift_name("printStackTrace()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedKotlinThrowable * _Nullable cause __attribute__((swift_name("cause")));
@property (readonly) NSString * _Nullable message __attribute__((swift_name("message")));
- (NSError *)asError __attribute__((swift_name("asError()")));
@end

__attribute__((swift_name("KotlinException")))
@interface SharedKotlinException : SharedKotlinThrowable
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("NetworkError")))
@interface SharedNetworkError : SharedKotlinException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (readonly) BOOL isAuthError __attribute__((swift_name("isAuthError")));
@property (readonly) NSString *message __attribute__((swift_name("message")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.DecodingError")))
@interface SharedNetworkErrorDecodingError : SharedNetworkError
- (instancetype)initWithReason:(SharedKotlinThrowable *)reason __attribute__((swift_name("init(reason:)"))) __attribute__((objc_designated_initializer));
- (SharedNetworkErrorDecodingError *)doCopyReason:(SharedKotlinThrowable *)reason __attribute__((swift_name("doCopy(reason:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedKotlinThrowable *reason __attribute__((swift_name("reason")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.InvalidURL")))
@interface SharedNetworkErrorInvalidURL : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)invalidURL __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorInvalidURL *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.NetworkUnavailable")))
@interface SharedNetworkErrorNetworkUnavailable : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)networkUnavailable __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorNetworkUnavailable *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.NoData")))
@interface SharedNetworkErrorNoData : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)noData __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorNoData *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.NotFound")))
@interface SharedNetworkErrorNotFound : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)notFound __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorNotFound *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.RateLimited")))
@interface SharedNetworkErrorRateLimited : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)rateLimited __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorRateLimited *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.ServerError")))
@interface SharedNetworkErrorServerError : SharedNetworkError
- (instancetype)initWithCode:(int32_t)code body:(NSString * _Nullable)body __attribute__((swift_name("init(code:body:)"))) __attribute__((objc_designated_initializer));
- (SharedNetworkErrorServerError *)doCopyCode:(int32_t)code body:(NSString * _Nullable)body __attribute__((swift_name("doCopy(code:body:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable body __attribute__((swift_name("body")));
@property (readonly) int32_t code __attribute__((swift_name("code")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.Timeout")))
@interface SharedNetworkErrorTimeout : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)timeout __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorTimeout *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.Unauthorized")))
@interface SharedNetworkErrorUnauthorized : SharedNetworkError
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)unauthorized __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedNetworkErrorUnauthorized *shared __attribute__((swift_name("shared")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("NetworkError.Unknown")))
@interface SharedNetworkErrorUnknown : SharedNetworkError
- (instancetype)initWithReason:(SharedKotlinThrowable *)reason __attribute__((swift_name("init(reason:)"))) __attribute__((objc_designated_initializer));
- (SharedNetworkErrorUnknown *)doCopyReason:(SharedKotlinThrowable *)reason __attribute__((swift_name("doCopy(reason:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedKotlinThrowable *reason __attribute__((swift_name("reason")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OpenFlixApi")))
@interface SharedOpenFlixApi : SharedBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)addM3USourceName:(NSString *)name url:(NSString *)url epgUrl:(NSString * _Nullable)epgUrl completionHandler:(void (^)(SharedM3USourceDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("addM3USource(name:url:epgUrl:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)addToPlaylistId:(int32_t)id mediaIds:(NSArray<SharedInt *> *)mediaIds completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("addToPlaylist(id:mediaIds:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)addToWatchlistMediaId:(int32_t)mediaId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("addToWatchlist(mediaId:completionHandler:)")));
- (void)configureServerUrl:(NSString *)serverUrl token:(NSString * _Nullable)token __attribute__((swift_name("configure(serverUrl:token:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)createPlaylistName:(NSString *)name completionHandler:(void (^)(SharedPlaylistDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("createPlaylist(name:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deletePath:(NSString *)path completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("delete(path:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteEPGSourceId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteEPGSource(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteM3USourceId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteM3USource(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deletePlaylistId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deletePlaylist(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteRecordingId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteRecording(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteSeriesRuleId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteSeriesRule(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteTeamPassId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteTeamPass(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteXtreamSourceId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteXtreamSource(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getPath:(NSString *)path queryParams:(NSDictionary<NSString *, NSString *> *)queryParams completionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("get(path:queryParams:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getCapabilitiesWithCompletionHandler:(void (^)(SharedServerCapabilitiesDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getCapabilities(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getChannelStreamId:(NSString *)id completionHandler:(void (^)(SharedChannelStreamResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getChannelStream(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getChannelsWithCompletionHandler:(void (^)(SharedChannelsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getChannels(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getEPGSourcesWithCompletionHandler:(void (^)(SharedEPGSourcesResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getEPGSources(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getGuideStartSec:(SharedLong * _Nullable)startSec endSec:(SharedLong * _Nullable)endSec completionHandler:(void (^)(SharedGuideResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getGuide(startSec:endSec:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getHomeUsersWithCompletionHandler:(void (^)(SharedHomeUsersResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getHomeUsers(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getHubsSectionId:(int32_t)sectionId completionHandler:(void (^)(SharedHubsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getHubs(sectionId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLibraryItemsSectionId:(int32_t)sectionId start:(SharedInt * _Nullable)start size:(SharedInt * _Nullable)size sort:(NSString * _Nullable)sort filters:(NSDictionary<NSString *, NSString *> * _Nullable)filters completionHandler:(void (^)(SharedMediaContainerResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLibraryItems(sectionId:start:size:sort:filters:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLibrarySectionsWithCompletionHandler:(void (^)(SharedLibrarySectionsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLibrarySections(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getM3USourcesWithCompletionHandler:(void (^)(SharedM3USourcesResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getM3USources(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getMediaChildrenKey:(int32_t)key completionHandler:(void (^)(SharedMediaContainerResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getMediaChildren(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getMediaDetailsKey:(int32_t)key completionHandler:(void (^)(SharedMediaContainerResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getMediaDetails(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getNowPlayingWithCompletionHandler:(void (^)(SharedNowPlayingResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getNowPlaying(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getOnDeckWithCompletionHandler:(void (^)(SharedMediaContainerResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getOnDeck(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getOnLaterMoviesWithCompletionHandler:(void (^)(SharedOnLaterResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getOnLaterMovies(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getOnLaterSportsLeague:(NSString * _Nullable)league team:(NSString * _Nullable)team completionHandler:(void (^)(SharedOnLaterResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getOnLaterSports(league:team:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getOnLaterStatsWithCompletionHandler:(void (^)(SharedOnLaterStatsResponseDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getOnLaterStats(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getPlaybackURLPath:(NSString *)path directPlay:(BOOL)directPlay completionHandler:(void (^)(SharedPlaybackURLResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getPlaybackURL(path:directPlay:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getPlaylistItemsId:(int32_t)id completionHandler:(void (^)(SharedPlaylistItemsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getPlaylistItems(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getPlaylistsWithCompletionHandler:(void (^)(SharedPlaylistsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getPlaylists(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getProfilesWithCompletionHandler:(void (^)(NSArray<SharedProfileDTO *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getProfiles(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecentlyAddedWithCompletionHandler:(void (^)(SharedMediaContainerResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecentlyAdded(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecordingId:(int32_t)id completionHandler:(void (^)(SharedRecordingDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecording(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecordingStreamId:(int32_t)id completionHandler:(void (^)(SharedRecordingStreamResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecordingStream(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecordingsStatus:(NSString * _Nullable)status completionHandler:(void (^)(SharedRecordingsResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecordings(status:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getSeriesRulesWithCompletionHandler:(void (^)(SharedSeriesRulesResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getSeriesRules(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getServerInfoWithCompletionHandler:(void (^)(SharedServerInfoDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getServerInfo(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getTeamPassesWithCompletionHandler:(void (^)(SharedTeamPassesResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getTeamPasses(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getUserWithCompletionHandler:(void (^)(SharedUserDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getUser(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getWatchlistWithCompletionHandler:(void (^)(SharedWatchlistResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getWatchlist(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getXtreamSourcesWithCompletionHandler:(void (^)(SharedXtreamSourcesResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getXtreamSources(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loginUsername:(NSString *)username password:(NSString *)password completionHandler:(void (^)(SharedAuthResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("login(username:password:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)logoutWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("logout(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)postPath:(NSString *)path body:(id _Nullable)body completionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("post(path:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)postVoidPath:(NSString *)path body:(id _Nullable)body completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("postVoid(path:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)putPath:(NSString *)path body:(id _Nullable)body completionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("put(path:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)putVoidPath:(NSString *)path body:(id _Nullable)body completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("putVoid(path:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)recordFromProgramChannelId:(NSString *)channelId programId:(NSString *)programId completionHandler:(void (^)(SharedRecordingDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("recordFromProgram(channelId:programId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)removeFromWatchlistMediaId:(int32_t)mediaId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("removeFromWatchlist(mediaId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)requestMethod:(SharedKtor_httpHttpMethod *)method path:(NSString *)path queryParams:(NSDictionary<NSString *, NSString *> *)queryParams body:(id _Nullable)body completionHandler:(void (^)(id _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("request(method:path:queryParams:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)requestVoidMethod:(SharedKtor_httpHttpMethod *)method path:(NSString *)path queryParams:(NSDictionary<NSString *, NSString *> *)queryParams body:(id _Nullable)body completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("requestVoid(method:path:queryParams:body:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)scheduleRecordingChannelId:(NSString *)channelId startTime:(NSString *)startTime endTime:(NSString *)endTime title:(NSString *)title completionHandler:(void (^)(SharedRecordingDTO * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("scheduleRecording(channelId:startTime:endTime:title:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)scrobbleKey:(int32_t)key completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("scrobble(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)searchQuery:(NSString *)query limit:(SharedInt * _Nullable)limit completionHandler:(void (^)(SharedSearchResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("search(query:limit:completionHandler:)")));
- (void)setTokenToken:(NSString * _Nullable)token __attribute__((swift_name("setToken(token:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)switchProfileUuid:(NSString *)uuid pin:(NSString * _Nullable)pin completionHandler:(void (^)(SharedSwitchProfileResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("switchProfile(uuid:pin:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)toggleFavoriteChannelId:(NSString *)channelId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("toggleFavorite(channelId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)unscrobbleKey:(int32_t)key completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("unscrobble(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)updateProgressKey:(int32_t)key time:(int32_t)time state:(NSString * _Nullable)state completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("updateProgress(key:time:state:completionHandler:)")));
@property (readonly) BOOL hasToken __attribute__((swift_name("hasToken")));
@property (readonly) BOOL isConfigured __attribute__((swift_name("isConfigured")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("AuthRepository")))
@interface SharedAuthRepository : SharedBase
- (instancetype)initWithApi:(SharedOpenFlixApi *)api __attribute__((swift_name("init(api:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getProfilesWithCompletionHandler:(void (^)(NSArray<SharedProfile *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getProfiles(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getUserWithCompletionHandler:(void (^)(SharedUser * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getUser(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loginUsername:(NSString *)username password:(NSString *)password completionHandler:(void (^)(SharedAuthResponse * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("login(username:password:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)logoutWithCompletionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("logout(completionHandler:)")));
- (void)restoreSessionServerUrl:(NSString *)serverUrl savedToken:(NSString *)savedToken __attribute__((swift_name("restoreSession(serverUrl:savedToken:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)switchProfileUuid:(NSString *)uuid pin:(NSString * _Nullable)pin completionHandler:(void (^)(SharedBoolean * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("switchProfile(uuid:pin:completionHandler:)")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> currentProfile __attribute__((swift_name("currentProfile")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> currentUser __attribute__((swift_name("currentUser")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> isAuthenticated __attribute__((swift_name("isAuthenticated")));
@end

__attribute__((swift_name("KotlinComparable")))
@protocol SharedKotlinComparable
@required
- (int32_t)compareToOther:(id _Nullable)other __attribute__((swift_name("compareTo(other:)")));
@end

__attribute__((swift_name("KotlinEnum")))
@interface SharedKotlinEnum<E> : SharedBase <SharedKotlinComparable>
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedKotlinEnumCompanion *companion __attribute__((swift_name("companion")));
- (int32_t)compareToOther:(E)other __attribute__((swift_name("compareTo(other:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t ordinal __attribute__((swift_name("ordinal")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelSortOrder")))
@interface SharedChannelSortOrder : SharedKotlinEnum<SharedChannelSortOrder *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SharedChannelSortOrder *number __attribute__((swift_name("number")));
@property (class, readonly) SharedChannelSortOrder *name __attribute__((swift_name("name")));
@property (class, readonly) SharedChannelSortOrder *favorites __attribute__((swift_name("favorites")));
+ (SharedKotlinArray<SharedChannelSortOrder *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedChannelSortOrder *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("DVRRepository")))
@interface SharedDVRRepository : SharedBase
- (instancetype)initWithApi:(SharedOpenFlixApi *)api __attribute__((swift_name("init(api:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteRecordingId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteRecording(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)deleteSeriesRuleId:(int32_t)id completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("deleteSeriesRule(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecordingId:(int32_t)id completionHandler:(void (^)(SharedRecording * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecording(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecordingStreamId:(int32_t)id completionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecordingStream(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getSeriesRulesWithCompletionHandler:(void (^)(NSArray<SharedSeriesRule *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getSeriesRules(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loadRecordingsWithCompletionHandler:(void (^)(NSArray<SharedRecording *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("loadRecordings(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)recordFromProgramChannelId:(NSString *)channelId programId:(NSString *)programId completionHandler:(void (^)(SharedRecording * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("recordFromProgram(channelId:programId:completionHandler:)")));
@property (readonly) NSArray<SharedRecording *> *activeRecordings __attribute__((swift_name("activeRecordings")));
@property (readonly) NSArray<SharedRecording *> *completedRecordings __attribute__((swift_name("completedRecordings")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> recordings __attribute__((swift_name("recordings")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> scheduled __attribute__((swift_name("scheduled")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LiveTVRepository")))
@interface SharedLiveTVRepository : SharedBase
- (instancetype)initWithApi:(SharedOpenFlixApi *)api __attribute__((swift_name("init(api:)"))) __attribute__((objc_designated_initializer));
- (NSArray<SharedChannel *> *)channelsByGroupGroup:(NSString * _Nullable)group __attribute__((swift_name("channelsByGroup(group:)")));
- (NSArray<SharedChannel *> *)channelsSortedBy:(SharedChannelSortOrder *)by __attribute__((swift_name("channelsSorted(by:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getChannelStreamId:(NSString *)id completionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getChannelStream(id:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getNowPlayingWithCompletionHandler:(void (^)(NSArray<SharedKotlinPair<NSString *, SharedProgram *> *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getNowPlaying(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loadChannelsWithCompletionHandler:(void (^)(NSArray<SharedChannel *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("loadChannels(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loadGuideStartSec:(SharedLong * _Nullable)startSec endSec:(SharedLong * _Nullable)endSec completionHandler:(void (^)(NSArray<SharedChannelWithPrograms *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("loadGuide(startSec:endSec:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)toggleFavoriteChannelId:(NSString *)channelId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("toggleFavorite(channelId:completionHandler:)")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> channels __attribute__((swift_name("channels")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> favoriteChannelIds __attribute__((swift_name("favoriteChannelIds")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaRepository")))
@interface SharedMediaRepository : SharedBase
- (instancetype)initWithApi:(SharedOpenFlixApi *)api __attribute__((swift_name("init(api:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getHubsSectionId:(int32_t)sectionId completionHandler:(void (^)(NSArray<SharedHub *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getHubs(sectionId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLibraryItemsSectionId:(int32_t)sectionId start:(SharedInt * _Nullable)start size:(SharedInt * _Nullable)size sort:(NSString * _Nullable)sort filters:(NSDictionary<NSString *, NSString *> * _Nullable)filters completionHandler:(void (^)(NSArray<SharedMediaItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLibraryItems(sectionId:start:size:sort:filters:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getLibrarySectionsWithCompletionHandler:(void (^)(NSArray<SharedLibrarySection *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getLibrarySections(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getMediaChildrenKey:(int32_t)key completionHandler:(void (^)(NSArray<SharedMediaItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getMediaChildren(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getMediaDetailsKey:(int32_t)key completionHandler:(void (^)(SharedMediaItem * _Nullable_result, NSError * _Nullable))completionHandler __attribute__((swift_name("getMediaDetails(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getOnDeckWithCompletionHandler:(void (^)(NSArray<SharedMediaItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getOnDeck(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getPlaybackURLPath:(NSString *)path directPlay:(BOOL)directPlay completionHandler:(void (^)(NSString * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getPlaybackURL(path:directPlay:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)getRecentlyAddedWithCompletionHandler:(void (^)(NSArray<SharedMediaItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("getRecentlyAdded(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)markUnwatchedKey:(int32_t)key completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("markUnwatched(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)markWatchedKey:(int32_t)key completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("markWatched(key:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)searchQuery:(NSString *)query limit:(SharedInt * _Nullable)limit completionHandler:(void (^)(NSArray<SharedMediaItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("search(query:limit:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)updateProgressKey:(int32_t)key time:(int32_t)time state:(NSString * _Nullable)state completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("updateProgress(key:time:state:completionHandler:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistRepository")))
@interface SharedWatchlistRepository : SharedBase
- (instancetype)initWithApi:(SharedOpenFlixApi *)api __attribute__((swift_name("init(api:)"))) __attribute__((objc_designated_initializer));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)addToWatchlistMediaId:(int32_t)mediaId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("addToWatchlist(mediaId:completionHandler:)")));
- (BOOL)isInWatchlistMediaId:(int32_t)mediaId __attribute__((swift_name("isInWatchlist(mediaId:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)loadWatchlistWithCompletionHandler:(void (^)(NSArray<SharedWatchlistItem *> * _Nullable, NSError * _Nullable))completionHandler __attribute__((swift_name("loadWatchlist(completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)removeFromWatchlistMediaId:(int32_t)mediaId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("removeFromWatchlist(mediaId:completionHandler:)")));

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)toggleWatchlistMediaId:(int32_t)mediaId completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("toggleWatchlist(mediaId:completionHandler:)")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> items __attribute__((swift_name("items")));
@property (readonly) id<SharedKotlinx_coroutines_coreStateFlow> watchlistIds __attribute__((swift_name("watchlistIds")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("CastMember")))
@interface SharedCastMember : SharedBase
- (instancetype)initWithId:(SharedInt * _Nullable)id name:(NSString *)name role:(NSString * _Nullable)role thumb:(NSString * _Nullable)thumb __attribute__((swift_name("init(id:name:role:thumb:)"))) __attribute__((objc_designated_initializer));
- (SharedCastMember *)doCopyId:(SharedInt * _Nullable)id name:(NSString *)name role:(NSString * _Nullable)role thumb:(NSString * _Nullable)thumb __attribute__((swift_name("doCopy(id:name:role:thumb:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable id __attribute__((swift_name("id")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString * _Nullable role __attribute__((swift_name("role")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Channel")))
@interface SharedChannel : SharedBase
- (instancetype)initWithId:(NSString *)id number:(SharedInt * _Nullable)number name:(NSString *)name logo:(NSString * _Nullable)logo sourceId:(NSString * _Nullable)sourceId sourceName:(NSString * _Nullable)sourceName streamUrl:(NSString * _Nullable)streamUrl enabled:(BOOL)enabled isFavorite:(BOOL)isFavorite group:(NSString * _Nullable)group archiveEnabled:(BOOL)archiveEnabled archiveDays:(int32_t)archiveDays nowPlaying:(SharedProgram * _Nullable)nowPlaying nextProgram:(SharedProgram * _Nullable)nextProgram __attribute__((swift_name("init(id:number:name:logo:sourceId:sourceName:streamUrl:enabled:isFavorite:group:archiveEnabled:archiveDays:nowPlaying:nextProgram:)"))) __attribute__((objc_designated_initializer));
- (SharedChannel *)doCopyId:(NSString *)id number:(SharedInt * _Nullable)number name:(NSString *)name logo:(NSString * _Nullable)logo sourceId:(NSString * _Nullable)sourceId sourceName:(NSString * _Nullable)sourceName streamUrl:(NSString * _Nullable)streamUrl enabled:(BOOL)enabled isFavorite:(BOOL)isFavorite group:(NSString * _Nullable)group archiveEnabled:(BOOL)archiveEnabled archiveDays:(int32_t)archiveDays nowPlaying:(SharedProgram * _Nullable)nowPlaying nextProgram:(SharedProgram * _Nullable)nextProgram __attribute__((swift_name("doCopy(id:number:name:logo:sourceId:sourceName:streamUrl:enabled:isFavorite:group:archiveEnabled:archiveDays:nowPlaying:nextProgram:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t archiveDays __attribute__((swift_name("archiveDays")));
@property (readonly) BOOL archiveEnabled __attribute__((swift_name("archiveEnabled")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString *displayNumber __attribute__((swift_name("displayNumber")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) NSString * _Nullable group __attribute__((swift_name("group")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) BOOL isFavorite __attribute__((swift_name("isFavorite")));
@property (readonly) BOOL isHD __attribute__((swift_name("isHD")));
@property (readonly) NSString * _Nullable logo __attribute__((swift_name("logo")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property SharedProgram * _Nullable nextProgram __attribute__((swift_name("nextProgram")));
@property SharedProgram * _Nullable nowPlaying __attribute__((swift_name("nowPlaying")));
@property (readonly) SharedInt * _Nullable number __attribute__((swift_name("number")));
@property (readonly) double sortKey __attribute__((swift_name("sortKey")));
@property (readonly) NSString * _Nullable sourceId __attribute__((swift_name("sourceId")));
@property (readonly) NSString * _Nullable sourceName __attribute__((swift_name("sourceName")));
@property (readonly) NSString * _Nullable streamUrl __attribute__((swift_name("streamUrl")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroup")))
@interface SharedChannelGroup : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name enabled:(BOOL)enabled members:(NSArray<SharedChannelGroupMember *> *)members __attribute__((swift_name("init(id:name:enabled:members:)"))) __attribute__((objc_designated_initializer));
- (SharedChannelGroup *)doCopyId:(int32_t)id name:(NSString *)name enabled:(BOOL)enabled members:(NSArray<SharedChannelGroupMember *> *)members __attribute__((swift_name("doCopy(id:name:enabled:members:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSArray<SharedChannelGroupMember *> *members __attribute__((swift_name("members")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelGroupMember")))
@interface SharedChannelGroupMember : SharedBase
- (instancetype)initWithChannelId:(NSString *)channelId priority:(int32_t)priority channelName:(NSString * _Nullable)channelName __attribute__((swift_name("init(channelId:priority:channelName:)"))) __attribute__((objc_designated_initializer));
- (SharedChannelGroupMember *)doCopyChannelId:(NSString *)channelId priority:(int32_t)priority channelName:(NSString * _Nullable)channelName __attribute__((swift_name("doCopy(channelId:priority:channelName:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelName __attribute__((swift_name("channelName")));
@property (readonly) int32_t priority __attribute__((swift_name("priority")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ChannelWithPrograms")))
@interface SharedChannelWithPrograms : SharedBase
- (instancetype)initWithChannel:(SharedChannel *)channel programs:(NSArray<SharedProgram *> *)programs __attribute__((swift_name("init(channel:programs:)"))) __attribute__((objc_designated_initializer));
- (SharedChannelWithPrograms *)doCopyChannel:(SharedChannel *)channel programs:(NSArray<SharedProgram *> *)programs __attribute__((swift_name("doCopy(channel:programs:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedProgram * _Nullable)programAtTimestamp:(int64_t)timestamp __attribute__((swift_name("programAt(timestamp:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedChannel *channel __attribute__((swift_name("channel")));
@property (readonly) SharedProgram * _Nullable currentProgram __attribute__((swift_name("currentProgram")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSArray<SharedProgram *> *programs __attribute__((swift_name("programs")));
@property (readonly) NSArray<SharedProgram *> *upcomingPrograms __attribute__((swift_name("upcomingPrograms")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Commercial")))
@interface SharedCommercial : SharedBase
- (instancetype)initWithStart:(int32_t)start end:(int32_t)end __attribute__((swift_name("init(start:end:)"))) __attribute__((objc_designated_initializer));
- (SharedCommercial *)doCopyStart:(int32_t)start end:(int32_t)end __attribute__((swift_name("doCopy(start:end:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t duration __attribute__((swift_name("duration")));
@property (readonly) int32_t end __attribute__((swift_name("end")));
@property (readonly) int32_t endSeconds __attribute__((swift_name("endSeconds")));
@property (readonly) int32_t start __attribute__((swift_name("start")));
@property (readonly) int32_t startSeconds __attribute__((swift_name("startSeconds")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSource")))
@interface SharedEPGSource : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name url:(NSString *)url type:(SharedEPGSourceType *)type enabled:(BOOL)enabled lastFetched:(SharedLong * _Nullable)lastFetched channelCount:(int32_t)channelCount programCount:(int32_t)programCount __attribute__((swift_name("init(id:name:url:type:enabled:lastFetched:channelCount:programCount:)"))) __attribute__((objc_designated_initializer));
- (SharedEPGSource *)doCopyId:(int32_t)id name:(NSString *)name url:(NSString *)url type:(SharedEPGSourceType *)type enabled:(BOOL)enabled lastFetched:(SharedLong * _Nullable)lastFetched channelCount:(int32_t)channelCount programCount:(int32_t)programCount __attribute__((swift_name("doCopy(id:name:url:type:enabled:lastFetched:channelCount:programCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t channelCount __attribute__((swift_name("channelCount")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedLong * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t programCount __attribute__((swift_name("programCount")));
@property (readonly) SharedEPGSourceType *type __attribute__((swift_name("type")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourceType")))
@interface SharedEPGSourceType : SharedKotlinEnum<SharedEPGSourceType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedEPGSourceTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) SharedEPGSourceType *xmltv __attribute__((swift_name("xmltv")));
@property (class, readonly) SharedEPGSourceType *gracenote __attribute__((swift_name("gracenote")));
+ (SharedKotlinArray<SharedEPGSourceType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedEPGSourceType *> *entries __attribute__((swift_name("entries")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("EPGSourceType.Companion")))
@interface SharedEPGSourceTypeCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedEPGSourceTypeCompanion *shared __attribute__((swift_name("shared")));
- (SharedEPGSourceType *)fromValueValue:(NSString *)value __attribute__((swift_name("fromValue(value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Hub")))
@interface SharedHub : SharedBase
- (instancetype)initWithKey:(NSString * _Nullable)key hubKey:(NSString * _Nullable)hubKey hubIdentifier:(NSString * _Nullable)hubIdentifier type:(NSString *)type title:(NSString *)title size:(int32_t)size more:(BOOL)more style:(NSString * _Nullable)style promoted:(BOOL)promoted items:(NSArray<SharedMediaItem *> *)items __attribute__((swift_name("init(key:hubKey:hubIdentifier:type:title:size:more:style:promoted:items:)"))) __attribute__((objc_designated_initializer));
- (SharedHub *)doCopyKey:(NSString * _Nullable)key hubKey:(NSString * _Nullable)hubKey hubIdentifier:(NSString * _Nullable)hubIdentifier type:(NSString *)type title:(NSString *)title size:(int32_t)size more:(BOOL)more style:(NSString * _Nullable)style promoted:(BOOL)promoted items:(NSArray<SharedMediaItem *> *)items __attribute__((swift_name("doCopy(key:hubKey:hubIdentifier:type:title:size:more:style:promoted:items:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable hubIdentifier __attribute__((swift_name("hubIdentifier")));
@property (readonly) NSString * _Nullable hubKey __attribute__((swift_name("hubKey")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSArray<SharedMediaItem *> *items __attribute__((swift_name("items")));
@property (readonly) NSString * _Nullable key __attribute__((swift_name("key")));
@property (readonly) BOOL more __attribute__((swift_name("more")));
@property (readonly) BOOL promoted __attribute__((swift_name("promoted")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@property (readonly) NSString * _Nullable style __attribute__((swift_name("style")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) NSString *type __attribute__((swift_name("type")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySection")))
@interface SharedLibrarySection : SharedBase
- (instancetype)initWithId:(int32_t)id key:(NSString *)key type:(SharedLibrarySectionType *)type title:(NSString *)title agent:(NSString * _Nullable)agent scanner:(NSString * _Nullable)scanner language:(NSString * _Nullable)language uuid:(NSString * _Nullable)uuid updatedAt:(SharedLong * _Nullable)updatedAt scannedAt:(SharedLong * _Nullable)scannedAt hidden:(BOOL)hidden __attribute__((swift_name("init(id:key:type:title:agent:scanner:language:uuid:updatedAt:scannedAt:hidden:)"))) __attribute__((objc_designated_initializer));
- (SharedLibrarySection *)doCopyId:(int32_t)id key:(NSString *)key type:(SharedLibrarySectionType *)type title:(NSString *)title agent:(NSString * _Nullable)agent scanner:(NSString * _Nullable)scanner language:(NSString * _Nullable)language uuid:(NSString * _Nullable)uuid updatedAt:(SharedLong * _Nullable)updatedAt scannedAt:(SharedLong * _Nullable)scannedAt hidden:(BOOL)hidden __attribute__((swift_name("doCopy(id:key:type:title:agent:scanner:language:uuid:updatedAt:scannedAt:hidden:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable agent __attribute__((swift_name("agent")));
@property (readonly) BOOL hidden __attribute__((swift_name("hidden")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) NSString * _Nullable language __attribute__((swift_name("language")));
@property (readonly) SharedLong * _Nullable scannedAt __attribute__((swift_name("scannedAt")));
@property (readonly) NSString * _Nullable scanner __attribute__((swift_name("scanner")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) SharedLibrarySectionType *type __attribute__((swift_name("type")));
@property (readonly) SharedLong * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@property (readonly) NSString * _Nullable uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionType")))
@interface SharedLibrarySectionType : SharedKotlinEnum<SharedLibrarySectionType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedLibrarySectionTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) SharedLibrarySectionType *movie __attribute__((swift_name("movie")));
@property (class, readonly) SharedLibrarySectionType *show __attribute__((swift_name("show")));
@property (class, readonly) SharedLibrarySectionType *artist __attribute__((swift_name("artist")));
@property (class, readonly) SharedLibrarySectionType *photo __attribute__((swift_name("photo")));
@property (class, readonly) SharedLibrarySectionType *mixed __attribute__((swift_name("mixed")));
+ (SharedKotlinArray<SharedLibrarySectionType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedLibrarySectionType *> *entries __attribute__((swift_name("entries")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("LibrarySectionType.Companion")))
@interface SharedLibrarySectionTypeCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedLibrarySectionTypeCompanion *shared __attribute__((swift_name("shared")));
- (SharedLibrarySectionType *)fromValueValue:(NSString *)value __attribute__((swift_name("fromValue(value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("M3USource")))
@interface SharedM3USource : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name url:(NSString *)url epgUrl:(NSString * _Nullable)epgUrl enabled:(BOOL)enabled lastFetched:(SharedLong * _Nullable)lastFetched importVod:(BOOL)importVod importSeries:(BOOL)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(int32_t)channelCount __attribute__((swift_name("init(id:name:url:epgUrl:enabled:lastFetched:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:)"))) __attribute__((objc_designated_initializer));
- (SharedM3USource *)doCopyId:(int32_t)id name:(NSString *)name url:(NSString *)url epgUrl:(NSString * _Nullable)epgUrl enabled:(BOOL)enabled lastFetched:(SharedLong * _Nullable)lastFetched importVod:(BOOL)importVod importSeries:(BOOL)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(int32_t)channelCount __attribute__((swift_name("doCopy(id:name:url:epgUrl:enabled:lastFetched:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t channelCount __attribute__((swift_name("channelCount")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) NSString * _Nullable epgUrl __attribute__((swift_name("epgUrl")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) BOOL importSeries __attribute__((swift_name("importSeries")));
@property (readonly) BOOL importVod __attribute__((swift_name("importVod")));
@property (readonly) SharedLong * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) SharedInt * _Nullable seriesLibraryId __attribute__((swift_name("seriesLibraryId")));
@property (readonly) NSString *url __attribute__((swift_name("url")));
@property (readonly) SharedInt * _Nullable vodLibraryId __attribute__((swift_name("vodLibraryId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaCollection")))
@interface SharedMediaCollection : SharedBase
- (instancetype)initWithId:(int32_t)id key:(NSString *)key title:(NSString *)title summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art childCount:(int32_t)childCount addedAt:(SharedLong * _Nullable)addedAt updatedAt:(SharedLong * _Nullable)updatedAt __attribute__((swift_name("init(id:key:title:summary:thumb:art:childCount:addedAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
- (SharedMediaCollection *)doCopyId:(int32_t)id key:(NSString *)key title:(NSString *)title summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art childCount:(int32_t)childCount addedAt:(SharedLong * _Nullable)addedAt updatedAt:(SharedLong * _Nullable)updatedAt __attribute__((swift_name("doCopy(id:key:title:summary:thumb:art:childCount:addedAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedLong * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) int32_t childCount __attribute__((swift_name("childCount")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) NSString * _Nullable summary __attribute__((swift_name("summary")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) SharedLong * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaItem")))
@interface SharedMediaItem : SharedBase
- (instancetype)initWithId:(int32_t)id key:(NSString *)key guid:(NSString * _Nullable)guid type:(SharedMediaType *)type title:(NSString *)title originalTitle:(NSString * _Nullable)originalTitle tagline:(NSString * _Nullable)tagline summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art banner:(NSString * _Nullable)banner year:(SharedInt * _Nullable)year duration:(SharedInt * _Nullable)duration viewOffset:(SharedInt * _Nullable)viewOffset viewCount:(SharedInt * _Nullable)viewCount contentRating:(NSString * _Nullable)contentRating audienceRating:(SharedDouble * _Nullable)audienceRating rating:(SharedDouble * _Nullable)rating studio:(NSString * _Nullable)studio addedAt:(SharedLong * _Nullable)addedAt originallyAvailableAt:(NSString * _Nullable)originallyAvailableAt leafCount:(SharedInt * _Nullable)leafCount viewedLeafCount:(SharedInt * _Nullable)viewedLeafCount childCount:(SharedInt * _Nullable)childCount index:(SharedInt * _Nullable)index parentIndex:(SharedInt * _Nullable)parentIndex parentRatingKey:(SharedInt * _Nullable)parentRatingKey parentTitle:(NSString * _Nullable)parentTitle grandparentRatingKey:(SharedInt * _Nullable)grandparentRatingKey grandparentTitle:(NSString * _Nullable)grandparentTitle grandparentThumb:(NSString * _Nullable)grandparentThumb genres:(NSArray<NSString *> *)genres roles:(NSArray<SharedCastMember *> *)roles directors:(NSArray<NSString *> *)directors writers:(NSArray<NSString *> *)writers countries:(NSArray<NSString *> *)countries mediaVersions:(NSArray<SharedMediaVersion *> *)mediaVersions __attribute__((swift_name("init(id:key:guid:type:title:originalTitle:tagline:summary:thumb:art:banner:year:duration:viewOffset:viewCount:contentRating:audienceRating:rating:studio:addedAt:originallyAvailableAt:leafCount:viewedLeafCount:childCount:index:parentIndex:parentRatingKey:parentTitle:grandparentRatingKey:grandparentTitle:grandparentThumb:genres:roles:directors:writers:countries:mediaVersions:)"))) __attribute__((objc_designated_initializer));
- (SharedMediaItem *)doCopyId:(int32_t)id key:(NSString *)key guid:(NSString * _Nullable)guid type:(SharedMediaType *)type title:(NSString *)title originalTitle:(NSString * _Nullable)originalTitle tagline:(NSString * _Nullable)tagline summary:(NSString * _Nullable)summary thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art banner:(NSString * _Nullable)banner year:(SharedInt * _Nullable)year duration:(SharedInt * _Nullable)duration viewOffset:(SharedInt * _Nullable)viewOffset viewCount:(SharedInt * _Nullable)viewCount contentRating:(NSString * _Nullable)contentRating audienceRating:(SharedDouble * _Nullable)audienceRating rating:(SharedDouble * _Nullable)rating studio:(NSString * _Nullable)studio addedAt:(SharedLong * _Nullable)addedAt originallyAvailableAt:(NSString * _Nullable)originallyAvailableAt leafCount:(SharedInt * _Nullable)leafCount viewedLeafCount:(SharedInt * _Nullable)viewedLeafCount childCount:(SharedInt * _Nullable)childCount index:(SharedInt * _Nullable)index parentIndex:(SharedInt * _Nullable)parentIndex parentRatingKey:(SharedInt * _Nullable)parentRatingKey parentTitle:(NSString * _Nullable)parentTitle grandparentRatingKey:(SharedInt * _Nullable)grandparentRatingKey grandparentTitle:(NSString * _Nullable)grandparentTitle grandparentThumb:(NSString * _Nullable)grandparentThumb genres:(NSArray<NSString *> *)genres roles:(NSArray<SharedCastMember *> *)roles directors:(NSArray<NSString *> *)directors writers:(NSArray<NSString *> *)writers countries:(NSArray<NSString *> *)countries mediaVersions:(NSArray<SharedMediaVersion *> *)mediaVersions __attribute__((swift_name("doCopy(id:key:guid:type:title:originalTitle:tagline:summary:thumb:art:banner:year:duration:viewOffset:viewCount:contentRating:audienceRating:rating:studio:addedAt:originallyAvailableAt:leafCount:viewedLeafCount:childCount:index:parentIndex:parentRatingKey:parentTitle:grandparentRatingKey:grandparentTitle:grandparentThumb:genres:roles:directors:writers:countries:mediaVersions:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedLong * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) SharedDouble * _Nullable audienceRating __attribute__((swift_name("audienceRating")));
@property (readonly) NSString * _Nullable audioChannels __attribute__((swift_name("audioChannels")));
@property (readonly) NSString * _Nullable banner __attribute__((swift_name("banner")));
@property (readonly) NSString * _Nullable bestThumb __attribute__((swift_name("bestThumb")));
@property (readonly) SharedInt * _Nullable childCount __attribute__((swift_name("childCount")));
@property (readonly) NSString * _Nullable contentRating __attribute__((swift_name("contentRating")));
@property (readonly) NSArray<NSString *> *countries __attribute__((swift_name("countries")));
@property (readonly) NSArray<NSString *> *directors __attribute__((swift_name("directors")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable episodeLabel __attribute__((swift_name("episodeLabel")));
@property (readonly) NSString *fullTitle __attribute__((swift_name("fullTitle")));
@property (readonly) NSArray<NSString *> *genres __attribute__((swift_name("genres")));
@property (readonly) SharedInt * _Nullable grandparentRatingKey __attribute__((swift_name("grandparentRatingKey")));
@property (readonly) NSString * _Nullable grandparentThumb __attribute__((swift_name("grandparentThumb")));
@property (readonly) NSString * _Nullable grandparentTitle __attribute__((swift_name("grandparentTitle")));
@property (readonly) NSString * _Nullable guid __attribute__((swift_name("guid")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable index __attribute__((swift_name("index")));
@property (readonly) BOOL isInProgress __attribute__((swift_name("isInProgress")));
@property (readonly) BOOL isWatched __attribute__((swift_name("isWatched")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) SharedInt * _Nullable leafCount __attribute__((swift_name("leafCount")));
@property (readonly) NSArray<SharedMediaVersion *> *mediaVersions __attribute__((swift_name("mediaVersions")));
@property (readonly) NSString * _Nullable originalTitle __attribute__((swift_name("originalTitle")));
@property (readonly) NSString * _Nullable originallyAvailableAt __attribute__((swift_name("originallyAvailableAt")));
@property (readonly) SharedInt * _Nullable parentIndex __attribute__((swift_name("parentIndex")));
@property (readonly) SharedInt * _Nullable parentRatingKey __attribute__((swift_name("parentRatingKey")));
@property (readonly) NSString * _Nullable parentTitle __attribute__((swift_name("parentTitle")));
@property (readonly) SharedMediaStream * _Nullable primaryStream __attribute__((swift_name("primaryStream")));
@property (readonly) double progress __attribute__((swift_name("progress")));
@property (readonly) double progressPercent __attribute__((swift_name("progressPercent")));
@property (readonly) SharedDouble * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) SharedInt * _Nullable remainingDuration __attribute__((swift_name("remainingDuration")));
@property (readonly) NSString * _Nullable resolution __attribute__((swift_name("resolution")));
@property (readonly) NSArray<SharedCastMember *> *roles __attribute__((swift_name("roles")));
@property (readonly) NSString * _Nullable studio __attribute__((swift_name("studio")));
@property (readonly) NSString * _Nullable summary __attribute__((swift_name("summary")));
@property (readonly) NSString * _Nullable tagline __attribute__((swift_name("tagline")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) SharedMediaType *type __attribute__((swift_name("type")));
@property (readonly) SharedInt * _Nullable viewCount __attribute__((swift_name("viewCount")));
@property (readonly) SharedInt * _Nullable viewOffset __attribute__((swift_name("viewOffset")));
@property (readonly) SharedInt * _Nullable viewedLeafCount __attribute__((swift_name("viewedLeafCount")));
@property (readonly) NSArray<NSString *> *writers __attribute__((swift_name("writers")));
@property (readonly) SharedInt * _Nullable year __attribute__((swift_name("year")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaPart")))
@interface SharedMediaPart : SharedBase
- (instancetype)initWithId:(int32_t)id key:(NSString *)key duration:(SharedInt * _Nullable)duration file:(NSString * _Nullable)file size:(SharedInt * _Nullable)size container:(NSString * _Nullable)container streams:(NSArray<SharedMediaStream *> *)streams __attribute__((swift_name("init(id:key:duration:file:size:container:streams:)"))) __attribute__((objc_designated_initializer));
- (SharedMediaPart *)doCopyId:(int32_t)id key:(NSString *)key duration:(SharedInt * _Nullable)duration file:(NSString * _Nullable)file size:(SharedInt * _Nullable)size container:(NSString * _Nullable)container streams:(NSArray<SharedMediaStream *> *)streams __attribute__((swift_name("doCopy(id:key:duration:file:size:container:streams:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable container __attribute__((swift_name("container")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) NSString * _Nullable file __attribute__((swift_name("file")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *key __attribute__((swift_name("key")));
@property (readonly) SharedInt * _Nullable size __attribute__((swift_name("size")));
@property (readonly) NSArray<SharedMediaStream *> *streams __attribute__((swift_name("streams")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaStream")))
@interface SharedMediaStream : SharedBase
- (instancetype)initWithId:(int32_t)id type:(SharedStreamType *)type codec:(NSString * _Nullable)codec index:(SharedInt * _Nullable)index language:(NSString * _Nullable)language languageCode:(NSString * _Nullable)languageCode displayTitle:(NSString * _Nullable)displayTitle selected:(BOOL)selected forced:(BOOL)forced isDefault:(BOOL)isDefault title:(NSString * _Nullable)title width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height bitrate:(SharedInt * _Nullable)bitrate frameRate:(SharedDouble * _Nullable)frameRate channels:(SharedInt * _Nullable)channels samplingRate:(SharedInt * _Nullable)samplingRate __attribute__((swift_name("init(id:type:codec:index:language:languageCode:displayTitle:selected:forced:isDefault:title:width:height:bitrate:frameRate:channels:samplingRate:)"))) __attribute__((objc_designated_initializer));
- (SharedMediaStream *)doCopyId:(int32_t)id type:(SharedStreamType *)type codec:(NSString * _Nullable)codec index:(SharedInt * _Nullable)index language:(NSString * _Nullable)language languageCode:(NSString * _Nullable)languageCode displayTitle:(NSString * _Nullable)displayTitle selected:(BOOL)selected forced:(BOOL)forced isDefault:(BOOL)isDefault title:(NSString * _Nullable)title width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height bitrate:(SharedInt * _Nullable)bitrate frameRate:(SharedDouble * _Nullable)frameRate channels:(SharedInt * _Nullable)channels samplingRate:(SharedInt * _Nullable)samplingRate __attribute__((swift_name("doCopy(id:type:codec:index:language:languageCode:displayTitle:selected:forced:isDefault:title:width:height:bitrate:frameRate:channels:samplingRate:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable bitrate __attribute__((swift_name("bitrate")));
@property (readonly) SharedInt * _Nullable channels __attribute__((swift_name("channels")));
@property (readonly) NSString * _Nullable codec __attribute__((swift_name("codec")));
@property (readonly) NSString * _Nullable displayTitle __attribute__((swift_name("displayTitle")));
@property (readonly) BOOL forced __attribute__((swift_name("forced")));
@property (readonly) SharedDouble * _Nullable frameRate __attribute__((swift_name("frameRate")));
@property (readonly) SharedInt * _Nullable height __attribute__((swift_name("height")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedInt * _Nullable index __attribute__((swift_name("index")));
@property (readonly) BOOL isDefault __attribute__((swift_name("isDefault")));
@property (readonly) NSString * _Nullable language __attribute__((swift_name("language")));
@property (readonly) NSString * _Nullable languageCode __attribute__((swift_name("languageCode")));
@property (readonly) SharedInt * _Nullable samplingRate __attribute__((swift_name("samplingRate")));
@property (readonly) BOOL selected __attribute__((swift_name("selected")));
@property (readonly) NSString * _Nullable title __attribute__((swift_name("title")));
@property (readonly) SharedStreamType *type __attribute__((swift_name("type")));
@property (readonly) SharedInt * _Nullable width __attribute__((swift_name("width")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaType")))
@interface SharedMediaType : SharedKotlinEnum<SharedMediaType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedMediaTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) SharedMediaType *movie __attribute__((swift_name("movie")));
@property (class, readonly) SharedMediaType *show __attribute__((swift_name("show")));
@property (class, readonly) SharedMediaType *season __attribute__((swift_name("season")));
@property (class, readonly) SharedMediaType *episode __attribute__((swift_name("episode")));
@property (class, readonly) SharedMediaType *artist __attribute__((swift_name("artist")));
@property (class, readonly) SharedMediaType *album __attribute__((swift_name("album")));
@property (class, readonly) SharedMediaType *track __attribute__((swift_name("track")));
@property (class, readonly) SharedMediaType *photo __attribute__((swift_name("photo")));
+ (SharedKotlinArray<SharedMediaType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedMediaType *> *entries __attribute__((swift_name("entries")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaType.Companion")))
@interface SharedMediaTypeCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedMediaTypeCompanion *shared __attribute__((swift_name("shared")));
- (SharedMediaType *)fromValueValue:(NSString *)value __attribute__((swift_name("fromValue(value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("MediaVersion")))
@interface SharedMediaVersion : SharedBase
- (instancetype)initWithId:(int32_t)id duration:(SharedInt * _Nullable)duration bitrate:(SharedInt * _Nullable)bitrate width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height audioChannels:(SharedInt * _Nullable)audioChannels audioCodec:(NSString * _Nullable)audioCodec videoCodec:(NSString * _Nullable)videoCodec resolution:(NSString * _Nullable)resolution container:(NSString * _Nullable)container parts:(NSArray<SharedMediaPart *> *)parts __attribute__((swift_name("init(id:duration:bitrate:width:height:audioChannels:audioCodec:videoCodec:resolution:container:parts:)"))) __attribute__((objc_designated_initializer));
- (SharedMediaVersion *)doCopyId:(int32_t)id duration:(SharedInt * _Nullable)duration bitrate:(SharedInt * _Nullable)bitrate width:(SharedInt * _Nullable)width height:(SharedInt * _Nullable)height audioChannels:(SharedInt * _Nullable)audioChannels audioCodec:(NSString * _Nullable)audioCodec videoCodec:(NSString * _Nullable)videoCodec resolution:(NSString * _Nullable)resolution container:(NSString * _Nullable)container parts:(NSArray<SharedMediaPart *> *)parts __attribute__((swift_name("doCopy(id:duration:bitrate:width:height:audioChannels:audioCodec:videoCodec:resolution:container:parts:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedInt * _Nullable audioChannels __attribute__((swift_name("audioChannels")));
@property (readonly) NSString * _Nullable audioCodec __attribute__((swift_name("audioCodec")));
@property (readonly) SharedInt * _Nullable bitrate __attribute__((swift_name("bitrate")));
@property (readonly) NSString * _Nullable container __attribute__((swift_name("container")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) SharedInt * _Nullable height __attribute__((swift_name("height")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSArray<SharedMediaPart *> *parts __attribute__((swift_name("parts")));
@property (readonly) NSString * _Nullable resolution __attribute__((swift_name("resolution")));
@property (readonly) NSString * _Nullable videoCodec __attribute__((swift_name("videoCodec")));
@property (readonly) SharedInt * _Nullable width __attribute__((swift_name("width")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterProgram")))
@interface SharedOnLaterProgram : SharedBase
- (instancetype)initWithChannelId:(NSString *)channelId channelName:(NSString *)channelName channelLogo:(NSString * _Nullable)channelLogo channelNumber:(SharedInt * _Nullable)channelNumber program:(SharedProgram *)program __attribute__((swift_name("init(channelId:channelName:channelLogo:channelNumber:program:)"))) __attribute__((objc_designated_initializer));
- (SharedOnLaterProgram *)doCopyChannelId:(NSString *)channelId channelName:(NSString *)channelName channelLogo:(NSString * _Nullable)channelLogo channelNumber:(SharedInt * _Nullable)channelNumber program:(SharedProgram *)program __attribute__((swift_name("doCopy(channelId:channelName:channelLogo:channelNumber:program:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelLogo __attribute__((swift_name("channelLogo")));
@property (readonly) NSString *channelName __attribute__((swift_name("channelName")));
@property (readonly) SharedInt * _Nullable channelNumber __attribute__((swift_name("channelNumber")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) SharedProgram *program __attribute__((swift_name("program")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("OnLaterStats")))
@interface SharedOnLaterStats : SharedBase
- (instancetype)initWithMovies:(int32_t)movies sports:(int32_t)sports kids:(int32_t)kids news:(int32_t)news premieres:(int32_t)premieres __attribute__((swift_name("init(movies:sports:kids:news:premieres:)"))) __attribute__((objc_designated_initializer));
- (SharedOnLaterStats *)doCopyMovies:(int32_t)movies sports:(int32_t)sports kids:(int32_t)kids news:(int32_t)news premieres:(int32_t)premieres __attribute__((swift_name("doCopy(movies:sports:kids:news:premieres:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t kids __attribute__((swift_name("kids")));
@property (readonly) int32_t movies __attribute__((swift_name("movies")));
@property (readonly) int32_t news __attribute__((swift_name("news")));
@property (readonly) int32_t premieres __attribute__((swift_name("premieres")));
@property (readonly) int32_t sports __attribute__((swift_name("sports")));
@property (readonly) int32_t total __attribute__((swift_name("total")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Playlist")))
@interface SharedPlaylist : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name itemCount:(int32_t)itemCount duration:(SharedInt * _Nullable)duration thumb:(NSString * _Nullable)thumb createdAt:(SharedLong * _Nullable)createdAt updatedAt:(SharedLong * _Nullable)updatedAt __attribute__((swift_name("init(id:name:itemCount:duration:thumb:createdAt:updatedAt:)"))) __attribute__((objc_designated_initializer));
- (SharedPlaylist *)doCopyId:(int32_t)id name:(NSString *)name itemCount:(int32_t)itemCount duration:(SharedInt * _Nullable)duration thumb:(NSString * _Nullable)thumb createdAt:(SharedLong * _Nullable)createdAt updatedAt:(SharedLong * _Nullable)updatedAt __attribute__((swift_name("doCopy(id:name:itemCount:duration:thumb:createdAt:updatedAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedLong * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) SharedInt * _Nullable duration __attribute__((swift_name("duration")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) int32_t itemCount __attribute__((swift_name("itemCount")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) SharedLong * _Nullable updatedAt __attribute__((swift_name("updatedAt")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("PlaylistItem")))
@interface SharedPlaylistItem : SharedBase
- (instancetype)initWithId:(int32_t)id playlistId:(int32_t)playlistId mediaId:(int32_t)mediaId index:(int32_t)index addedAt:(SharedLong * _Nullable)addedAt media:(SharedMediaItem * _Nullable)media __attribute__((swift_name("init(id:playlistId:mediaId:index:addedAt:media:)"))) __attribute__((objc_designated_initializer));
- (SharedPlaylistItem *)doCopyId:(int32_t)id playlistId:(int32_t)playlistId mediaId:(int32_t)mediaId index:(int32_t)index addedAt:(SharedLong * _Nullable)addedAt media:(SharedMediaItem * _Nullable)media __attribute__((swift_name("doCopy(id:playlistId:mediaId:index:addedAt:media:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedLong * _Nullable addedAt __attribute__((swift_name("addedAt")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) int32_t index __attribute__((swift_name("index")));
@property (readonly) SharedMediaItem * _Nullable media __attribute__((swift_name("media")));
@property (readonly) int32_t mediaId __attribute__((swift_name("mediaId")));
@property (readonly) int32_t playlistId __attribute__((swift_name("playlistId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Profile")))
@interface SharedProfile : SharedBase
- (instancetype)initWithId:(int32_t)id uuid:(NSString *)uuid name:(NSString *)name avatar:(NSString * _Nullable)avatar isKid:(BOOL)isKid isProtected:(BOOL)isProtected isAdmin:(BOOL)isAdmin isGuest:(BOOL)isGuest isRestricted:(BOOL)isRestricted __attribute__((swift_name("init(id:uuid:name:avatar:isKid:isProtected:isAdmin:isGuest:isRestricted:)"))) __attribute__((objc_designated_initializer));
- (SharedProfile *)doCopyId:(int32_t)id uuid:(NSString *)uuid name:(NSString *)name avatar:(NSString * _Nullable)avatar isKid:(BOOL)isKid isProtected:(BOOL)isProtected isAdmin:(BOOL)isAdmin isGuest:(BOOL)isGuest isRestricted:(BOOL)isRestricted __attribute__((swift_name("doCopy(id:uuid:name:avatar:isKid:isProtected:isAdmin:isGuest:isRestricted:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable avatar __attribute__((swift_name("avatar")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) NSString *initials __attribute__((swift_name("initials")));
@property (readonly) BOOL isAdmin __attribute__((swift_name("isAdmin")));
@property (readonly) BOOL isGuest __attribute__((swift_name("isGuest")));
@property (readonly) BOOL isKid __attribute__((swift_name("isKid")));
@property (readonly) BOOL isProtected __attribute__((swift_name("isProtected")));
@property (readonly) BOOL isRestricted __attribute__((swift_name("isRestricted")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString *uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Program")))
@interface SharedProgram : SharedBase
- (instancetype)initWithId:(NSString *)id title:(NSString *)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description startTimeMs:(int64_t)startTimeMs endTimeMs:(int64_t)endTimeMs duration:(int32_t)duration icon:(NSString * _Nullable)icon art:(NSString * _Nullable)art rating:(NSString * _Nullable)rating category:(NSString * _Nullable)category isNew:(BOOL)isNew isLive:(BOOL)isLive isPremiere:(BOOL)isPremiere isFinale:(BOOL)isFinale isSports:(BOOL)isSports isKids:(BOOL)isKids teams:(NSString * _Nullable)teams league:(NSString * _Nullable)league hasRecording:(BOOL)hasRecording recordingId:(NSString * _Nullable)recordingId __attribute__((swift_name("init(id:title:subtitle:description:startTimeMs:endTimeMs:duration:icon:art:rating:category:isNew:isLive:isPremiere:isFinale:isSports:isKids:teams:league:hasRecording:recordingId:)"))) __attribute__((objc_designated_initializer));
- (SharedProgram *)doCopyId:(NSString *)id title:(NSString *)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description startTimeMs:(int64_t)startTimeMs endTimeMs:(int64_t)endTimeMs duration:(int32_t)duration icon:(NSString * _Nullable)icon art:(NSString * _Nullable)art rating:(NSString * _Nullable)rating category:(NSString * _Nullable)category isNew:(BOOL)isNew isLive:(BOOL)isLive isPremiere:(BOOL)isPremiere isFinale:(BOOL)isFinale isSports:(BOOL)isSports isKids:(BOOL)isKids teams:(NSString * _Nullable)teams league:(NSString * _Nullable)league hasRecording:(BOOL)hasRecording recordingId:(NSString * _Nullable)recordingId __attribute__((swift_name("doCopy(id:title:subtitle:description:startTimeMs:endTimeMs:duration:icon:art:rating:category:isNew:isLive:isPremiere:isFinale:isSports:isKids:teams:league:hasRecording:recordingId:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) NSArray<NSString *> *badges __attribute__((swift_name("badges")));
@property (readonly) NSString * _Nullable category __attribute__((swift_name("category")));
@property (readonly) NSString * _Nullable description_ __attribute__((swift_name("description_")));
@property (readonly) int32_t duration __attribute__((swift_name("duration")));
@property (readonly) int64_t endTimeMs __attribute__((swift_name("endTimeMs")));
@property (readonly) NSString *fullTitle __attribute__((swift_name("fullTitle")));
@property (readonly) BOOL hasEnded __attribute__((swift_name("hasEnded")));
@property (readonly) BOOL hasRecording __attribute__((swift_name("hasRecording")));
@property (readonly) BOOL hasStarted __attribute__((swift_name("hasStarted")));
@property (readonly) NSString * _Nullable icon __attribute__((swift_name("icon")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) BOOL isCurrentlyAiring __attribute__((swift_name("isCurrentlyAiring")));
@property (readonly) BOOL isFinale __attribute__((swift_name("isFinale")));
@property (readonly) BOOL isKids __attribute__((swift_name("isKids")));
@property (readonly) BOOL isLive __attribute__((swift_name("isLive")));
@property (readonly) BOOL isNew __attribute__((swift_name("isNew")));
@property (readonly) BOOL isPremiere __attribute__((swift_name("isPremiere")));
@property (readonly) BOOL isSports __attribute__((swift_name("isSports")));
@property (readonly) NSString * _Nullable league __attribute__((swift_name("league")));
@property (readonly) double progress __attribute__((swift_name("progress")));
@property (readonly) NSString * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) NSString * _Nullable recordingId __attribute__((swift_name("recordingId")));
@property (readonly) int32_t remainingMinutes __attribute__((swift_name("remainingMinutes")));
@property (readonly) int64_t startTimeMs __attribute__((swift_name("startTimeMs")));
@property (readonly) NSString * _Nullable subtitle __attribute__((swift_name("subtitle")));
@property (readonly) NSString * _Nullable teams __attribute__((swift_name("teams")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Recording")))
@interface SharedRecording : SharedBase
- (instancetype)initWithId:(int32_t)id title:(NSString *)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art channelId:(NSString * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo startTimeMs:(int64_t)startTimeMs endTimeMs:(int64_t)endTimeMs duration:(int32_t)duration status:(SharedRecordingStatus *)status filePath:(NSString * _Nullable)filePath fileSize:(SharedInt * _Nullable)fileSize seasonNumber:(SharedInt * _Nullable)seasonNumber episodeNumber:(SharedInt * _Nullable)episodeNumber seriesRecord:(BOOL)seriesRecord seriesRuleId:(SharedInt * _Nullable)seriesRuleId genres:(NSArray<NSString *> *)genres contentRating:(NSString * _Nullable)contentRating year:(SharedInt * _Nullable)year rating:(SharedDouble * _Nullable)rating isMovie:(BOOL)isMovie viewOffset:(SharedInt * _Nullable)viewOffset commercials:(NSArray<SharedCommercial *> *)commercials priority:(int32_t)priority __attribute__((swift_name("init(id:title:subtitle:description:thumb:art:channelId:channelName:channelLogo:startTimeMs:endTimeMs:duration:status:filePath:fileSize:seasonNumber:episodeNumber:seriesRecord:seriesRuleId:genres:contentRating:year:rating:isMovie:viewOffset:commercials:priority:)"))) __attribute__((objc_designated_initializer));
- (SharedRecording *)doCopyId:(int32_t)id title:(NSString *)title subtitle:(NSString * _Nullable)subtitle description:(NSString * _Nullable)description thumb:(NSString * _Nullable)thumb art:(NSString * _Nullable)art channelId:(NSString * _Nullable)channelId channelName:(NSString * _Nullable)channelName channelLogo:(NSString * _Nullable)channelLogo startTimeMs:(int64_t)startTimeMs endTimeMs:(int64_t)endTimeMs duration:(int32_t)duration status:(SharedRecordingStatus *)status filePath:(NSString * _Nullable)filePath fileSize:(SharedInt * _Nullable)fileSize seasonNumber:(SharedInt * _Nullable)seasonNumber episodeNumber:(SharedInt * _Nullable)episodeNumber seriesRecord:(BOOL)seriesRecord seriesRuleId:(SharedInt * _Nullable)seriesRuleId genres:(NSArray<NSString *> *)genres contentRating:(NSString * _Nullable)contentRating year:(SharedInt * _Nullable)year rating:(SharedDouble * _Nullable)rating isMovie:(BOOL)isMovie viewOffset:(SharedInt * _Nullable)viewOffset commercials:(NSArray<SharedCommercial *> *)commercials priority:(int32_t)priority __attribute__((swift_name("doCopy(id:title:subtitle:description:thumb:art:channelId:channelName:channelLogo:startTimeMs:endTimeMs:duration:status:filePath:fileSize:seasonNumber:episodeNumber:seriesRecord:seriesRuleId:genres:contentRating:year:rating:isMovie:viewOffset:commercials:priority:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable art __attribute__((swift_name("art")));
@property (readonly) NSString * _Nullable channelId __attribute__((swift_name("channelId")));
@property (readonly) NSString * _Nullable channelLogo __attribute__((swift_name("channelLogo")));
@property (readonly) NSString * _Nullable channelName __attribute__((swift_name("channelName")));
@property (readonly) NSArray<SharedCommercial *> *commercials __attribute__((swift_name("commercials")));
@property (readonly) NSString * _Nullable contentRating __attribute__((swift_name("contentRating")));
@property (readonly) NSString * _Nullable description_ __attribute__((swift_name("description_")));
@property (readonly) int32_t duration __attribute__((swift_name("duration")));
@property (readonly) int64_t endTimeMs __attribute__((swift_name("endTimeMs")));
@property (readonly) NSString * _Nullable episodeLabel __attribute__((swift_name("episodeLabel")));
@property (readonly) SharedInt * _Nullable episodeNumber __attribute__((swift_name("episodeNumber")));
@property (readonly) NSString * _Nullable filePath __attribute__((swift_name("filePath")));
@property (readonly) SharedInt * _Nullable fileSize __attribute__((swift_name("fileSize")));
@property (readonly) NSString *fullTitle __attribute__((swift_name("fullTitle")));
@property (readonly) NSArray<NSString *> *genres __attribute__((swift_name("genres")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) BOOL isCurrentlyRecording __attribute__((swift_name("isCurrentlyRecording")));
@property (readonly) BOOL isInProgress __attribute__((swift_name("isInProgress")));
@property (readonly) BOOL isMovie __attribute__((swift_name("isMovie")));
@property (readonly) BOOL isUpcoming __attribute__((swift_name("isUpcoming")));
@property (readonly) int32_t priority __attribute__((swift_name("priority")));
@property (readonly) double progressPercent __attribute__((swift_name("progressPercent")));
@property (readonly) SharedDouble * _Nullable rating __attribute__((swift_name("rating")));
@property (readonly) SharedInt * _Nullable seasonNumber __attribute__((swift_name("seasonNumber")));
@property (readonly) BOOL seriesRecord __attribute__((swift_name("seriesRecord")));
@property (readonly) SharedInt * _Nullable seriesRuleId __attribute__((swift_name("seriesRuleId")));
@property (readonly) int64_t startTimeMs __attribute__((swift_name("startTimeMs")));
@property (readonly) SharedRecordingStatus *status __attribute__((swift_name("status")));
@property (readonly) NSString * _Nullable subtitle __attribute__((swift_name("subtitle")));
@property (readonly) NSString * _Nullable thumb __attribute__((swift_name("thumb")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@property (readonly) SharedInt * _Nullable viewOffset __attribute__((swift_name("viewOffset")));
@property (readonly) SharedInt * _Nullable year __attribute__((swift_name("year")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStatus")))
@interface SharedRecordingStatus : SharedKotlinEnum<SharedRecordingStatus *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedRecordingStatusCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) SharedRecordingStatus *scheduled __attribute__((swift_name("scheduled")));
@property (class, readonly) SharedRecordingStatus *recording __attribute__((swift_name("recording")));
@property (class, readonly) SharedRecordingStatus *completed __attribute__((swift_name("completed")));
@property (class, readonly) SharedRecordingStatus *failed __attribute__((swift_name("failed")));
+ (SharedKotlinArray<SharedRecordingStatus *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedRecordingStatus *> *entries __attribute__((swift_name("entries")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("RecordingStatus.Companion")))
@interface SharedRecordingStatusCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedRecordingStatusCompanion *shared __attribute__((swift_name("shared")));
- (SharedRecordingStatus *)fromValueValue:(NSString *)value __attribute__((swift_name("fromValue(value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("SeriesRule")))
@interface SharedSeriesRule : SharedBase
- (instancetype)initWithId:(int32_t)id title:(NSString *)title channelId:(NSString * _Nullable)channelId enabled:(BOOL)enabled prePadding:(int32_t)prePadding postPadding:(int32_t)postPadding keepCount:(int32_t)keepCount recordingCount:(int32_t)recordingCount __attribute__((swift_name("init(id:title:channelId:enabled:prePadding:postPadding:keepCount:recordingCount:)"))) __attribute__((objc_designated_initializer));
- (SharedSeriesRule *)doCopyId:(int32_t)id title:(NSString *)title channelId:(NSString * _Nullable)channelId enabled:(BOOL)enabled prePadding:(int32_t)prePadding postPadding:(int32_t)postPadding keepCount:(int32_t)keepCount recordingCount:(int32_t)recordingCount __attribute__((swift_name("doCopy(id:title:channelId:enabled:prePadding:postPadding:keepCount:recordingCount:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable channelId __attribute__((swift_name("channelId")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) int32_t keepCount __attribute__((swift_name("keepCount")));
@property (readonly) int32_t postPadding __attribute__((swift_name("postPadding")));
@property (readonly) int32_t prePadding __attribute__((swift_name("prePadding")));
@property (readonly) int32_t recordingCount __attribute__((swift_name("recordingCount")));
@property (readonly) NSString *title __attribute__((swift_name("title")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerCapabilities")))
@interface SharedServerCapabilities : SharedBase
- (instancetype)initWithLiveTV:(BOOL)liveTV dvr:(BOOL)dvr transcoding:(BOOL)transcoding offlineDownloads:(BOOL)offlineDownloads multiUser:(BOOL)multiUser watchParty:(BOOL)watchParty epgSources:(NSArray<NSString *> *)epgSources __attribute__((swift_name("init(liveTV:dvr:transcoding:offlineDownloads:multiUser:watchParty:epgSources:)"))) __attribute__((objc_designated_initializer));
- (SharedServerCapabilities *)doCopyLiveTV:(BOOL)liveTV dvr:(BOOL)dvr transcoding:(BOOL)transcoding offlineDownloads:(BOOL)offlineDownloads multiUser:(BOOL)multiUser watchParty:(BOOL)watchParty epgSources:(NSArray<NSString *> *)epgSources __attribute__((swift_name("doCopy(liveTV:dvr:transcoding:offlineDownloads:multiUser:watchParty:epgSources:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL dvr __attribute__((swift_name("dvr")));
@property (readonly) NSArray<NSString *> *epgSources __attribute__((swift_name("epgSources")));
@property (readonly) BOOL liveTV __attribute__((swift_name("liveTV")));
@property (readonly) BOOL multiUser __attribute__((swift_name("multiUser")));
@property (readonly) BOOL offlineDownloads __attribute__((swift_name("offlineDownloads")));
@property (readonly) BOOL transcoding __attribute__((swift_name("transcoding")));
@property (readonly) BOOL watchParty __attribute__((swift_name("watchParty")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("ServerInfo")))
@interface SharedServerInfo : SharedBase
- (instancetype)initWithName:(NSString *)name version:(NSString *)version platform:(NSString *)platform machineIdentifier:(NSString *)machineIdentifier isOwner:(BOOL)isOwner transcoderActive:(BOOL)transcoderActive __attribute__((swift_name("init(name:version:platform:machineIdentifier:isOwner:transcoderActive:)"))) __attribute__((objc_designated_initializer));
- (SharedServerInfo *)doCopyName:(NSString *)name version:(NSString *)version platform:(NSString *)platform machineIdentifier:(NSString *)machineIdentifier isOwner:(BOOL)isOwner transcoderActive:(BOOL)transcoderActive __attribute__((swift_name("doCopy(name:version:platform:machineIdentifier:isOwner:transcoderActive:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) BOOL isOwner __attribute__((swift_name("isOwner")));
@property (readonly) NSString *machineIdentifier __attribute__((swift_name("machineIdentifier")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString *platform __attribute__((swift_name("platform")));
@property (readonly) BOOL transcoderActive __attribute__((swift_name("transcoderActive")));
@property (readonly) NSString *version __attribute__((swift_name("version")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StreamType")))
@interface SharedStreamType : SharedKotlinEnum<SharedStreamType *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedStreamTypeCompanion *companion __attribute__((swift_name("companion")));
@property (class, readonly) SharedStreamType *video __attribute__((swift_name("video")));
@property (class, readonly) SharedStreamType *audio __attribute__((swift_name("audio")));
@property (class, readonly) SharedStreamType *subtitle __attribute__((swift_name("subtitle")));
+ (SharedKotlinArray<SharedStreamType *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedStreamType *> *entries __attribute__((swift_name("entries")));
@property (readonly) int32_t value __attribute__((swift_name("value")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("StreamType.Companion")))
@interface SharedStreamTypeCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedStreamTypeCompanion *shared __attribute__((swift_name("shared")));
- (SharedStreamType *)fromValueValue:(int32_t)value __attribute__((swift_name("fromValue(value:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Team")))
@interface SharedTeam : SharedBase
- (instancetype)initWithName:(NSString *)name aliases:(NSArray<NSString *> *)aliases logo:(NSString * _Nullable)logo __attribute__((swift_name("init(name:aliases:logo:)"))) __attribute__((objc_designated_initializer));
- (SharedTeam *)doCopyName:(NSString *)name aliases:(NSArray<NSString *> *)aliases logo:(NSString * _Nullable)logo __attribute__((swift_name("doCopy(name:aliases:logo:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<NSString *> *aliases __attribute__((swift_name("aliases")));
@property (readonly) NSString * _Nullable logo __attribute__((swift_name("logo")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TeamPass")))
@interface SharedTeamPass : SharedBase
- (instancetype)initWithId:(int32_t)id teamName:(NSString *)teamName teamAliases:(NSArray<NSString *> *)teamAliases league:(NSString *)league channelIds:(NSArray<NSString *> *)channelIds prePadding:(int32_t)prePadding postPadding:(int32_t)postPadding keepCount:(int32_t)keepCount priority:(int32_t)priority enabled:(BOOL)enabled upcomingCount:(int32_t)upcomingCount logoUrl:(NSString * _Nullable)logoUrl __attribute__((swift_name("init(id:teamName:teamAliases:league:channelIds:prePadding:postPadding:keepCount:priority:enabled:upcomingCount:logoUrl:)"))) __attribute__((objc_designated_initializer));
- (SharedTeamPass *)doCopyId:(int32_t)id teamName:(NSString *)teamName teamAliases:(NSArray<NSString *> *)teamAliases league:(NSString *)league channelIds:(NSArray<NSString *> *)channelIds prePadding:(int32_t)prePadding postPadding:(int32_t)postPadding keepCount:(int32_t)keepCount priority:(int32_t)priority enabled:(BOOL)enabled upcomingCount:(int32_t)upcomingCount logoUrl:(NSString * _Nullable)logoUrl __attribute__((swift_name("doCopy(id:teamName:teamAliases:league:channelIds:prePadding:postPadding:keepCount:priority:enabled:upcomingCount:logoUrl:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSArray<NSString *> *channelIds __attribute__((swift_name("channelIds")));
@property (readonly) NSString *displayName __attribute__((swift_name("displayName")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) int32_t keepCount __attribute__((swift_name("keepCount")));
@property (readonly) NSString *league __attribute__((swift_name("league")));
@property (readonly) NSString * _Nullable logoUrl __attribute__((swift_name("logoUrl")));
@property (readonly) int32_t postPadding __attribute__((swift_name("postPadding")));
@property (readonly) int32_t prePadding __attribute__((swift_name("prePadding")));
@property (readonly) int32_t priority __attribute__((swift_name("priority")));
@property (readonly) NSArray<NSString *> *teamAliases __attribute__((swift_name("teamAliases")));
@property (readonly) NSString *teamName __attribute__((swift_name("teamName")));
@property (readonly) int32_t upcomingCount __attribute__((swift_name("upcomingCount")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("TrailerInfo")))
@interface SharedTrailerInfo : SharedBase
- (instancetype)initWithYoutubeKey:(NSString *)youtubeKey name:(NSString *)name backdropPath:(NSString * _Nullable)backdropPath __attribute__((swift_name("init(youtubeKey:name:backdropPath:)"))) __attribute__((objc_designated_initializer));
- (SharedTrailerInfo *)doCopyYoutubeKey:(NSString *)youtubeKey name:(NSString *)name backdropPath:(NSString * _Nullable)backdropPath __attribute__((swift_name("doCopy(youtubeKey:name:backdropPath:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable backdropPath __attribute__((swift_name("backdropPath")));
@property (readonly) NSString *embedURL __attribute__((swift_name("embedURL")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString *thumbnailURL __attribute__((swift_name("thumbnailURL")));
@property (readonly) NSString *thumbnailURLMedium __attribute__((swift_name("thumbnailURLMedium")));
@property (readonly) NSString * _Nullable tmdbBackdropURL __attribute__((swift_name("tmdbBackdropURL")));
@property (readonly) NSString * _Nullable tmdbBackdropURLMedium __attribute__((swift_name("tmdbBackdropURLMedium")));
@property (readonly) NSString *watchURL __attribute__((swift_name("watchURL")));
@property (readonly) NSString *youtubeKey __attribute__((swift_name("youtubeKey")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("User")))
@interface SharedUser : SharedBase
- (instancetype)initWithId:(int32_t)id uuid:(NSString * _Nullable)uuid username:(NSString *)username email:(NSString * _Nullable)email displayName:(NSString * _Nullable)displayName avatar:(NSString * _Nullable)avatar isAdmin:(BOOL)isAdmin __attribute__((swift_name("init(id:uuid:username:email:displayName:avatar:isAdmin:)"))) __attribute__((objc_designated_initializer));
- (SharedUser *)doCopyId:(int32_t)id uuid:(NSString * _Nullable)uuid username:(NSString *)username email:(NSString * _Nullable)email displayName:(NSString * _Nullable)displayName avatar:(NSString * _Nullable)avatar isAdmin:(BOOL)isAdmin __attribute__((swift_name("doCopy(id:uuid:username:email:displayName:avatar:isAdmin:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString * _Nullable avatar __attribute__((swift_name("avatar")));
@property (readonly) NSString * _Nullable displayName __attribute__((swift_name("displayName")));
@property (readonly) NSString * _Nullable email __attribute__((swift_name("email")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) BOOL isAdmin __attribute__((swift_name("isAdmin")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) NSString *username __attribute__((swift_name("username")));
@property (readonly) NSString * _Nullable uuid __attribute__((swift_name("uuid")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("WatchlistItem")))
@interface SharedWatchlistItem : SharedBase
- (instancetype)initWithId:(int32_t)id mediaId:(int32_t)mediaId addedAt:(int64_t)addedAt media:(SharedMediaItem * _Nullable)media __attribute__((swift_name("init(id:mediaId:addedAt:media:)"))) __attribute__((objc_designated_initializer));
- (SharedWatchlistItem *)doCopyId:(int32_t)id mediaId:(int32_t)mediaId addedAt:(int64_t)addedAt media:(SharedMediaItem * _Nullable)media __attribute__((swift_name("doCopy(id:mediaId:addedAt:media:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int64_t addedAt __attribute__((swift_name("addedAt")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) SharedMediaItem * _Nullable media __attribute__((swift_name("media")));
@property (readonly) int32_t mediaId __attribute__((swift_name("mediaId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("XtreamSource")))
@interface SharedXtreamSource : SharedBase
- (instancetype)initWithId:(int32_t)id name:(NSString *)name serverUrl:(NSString *)serverUrl username:(NSString *)username enabled:(BOOL)enabled importLive:(BOOL)importLive importVod:(BOOL)importVod importSeries:(BOOL)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(int32_t)channelCount vodCount:(int32_t)vodCount seriesCount:(int32_t)seriesCount lastFetched:(SharedLong * _Nullable)lastFetched expirationDate:(SharedLong * _Nullable)expirationDate createdAt:(SharedLong * _Nullable)createdAt __attribute__((swift_name("init(id:name:serverUrl:username:enabled:importLive:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:vodCount:seriesCount:lastFetched:expirationDate:createdAt:)"))) __attribute__((objc_designated_initializer));
- (SharedXtreamSource *)doCopyId:(int32_t)id name:(NSString *)name serverUrl:(NSString *)serverUrl username:(NSString *)username enabled:(BOOL)enabled importLive:(BOOL)importLive importVod:(BOOL)importVod importSeries:(BOOL)importSeries vodLibraryId:(SharedInt * _Nullable)vodLibraryId seriesLibraryId:(SharedInt * _Nullable)seriesLibraryId channelCount:(int32_t)channelCount vodCount:(int32_t)vodCount seriesCount:(int32_t)seriesCount lastFetched:(SharedLong * _Nullable)lastFetched expirationDate:(SharedLong * _Nullable)expirationDate createdAt:(SharedLong * _Nullable)createdAt __attribute__((swift_name("doCopy(id:name:serverUrl:username:enabled:importLive:importVod:importSeries:vodLibraryId:seriesLibraryId:channelCount:vodCount:seriesCount:lastFetched:expirationDate:createdAt:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) int32_t channelCount __attribute__((swift_name("channelCount")));
@property (readonly) SharedLong * _Nullable createdAt __attribute__((swift_name("createdAt")));
@property (readonly) BOOL enabled __attribute__((swift_name("enabled")));
@property (readonly) SharedLong * _Nullable expirationDate __attribute__((swift_name("expirationDate")));
@property (readonly) int32_t id __attribute__((swift_name("id")));
@property (readonly) BOOL importLive __attribute__((swift_name("importLive")));
@property (readonly) BOOL importSeries __attribute__((swift_name("importSeries")));
@property (readonly) BOOL importVod __attribute__((swift_name("importVod")));
@property (readonly) BOOL isExpired __attribute__((swift_name("isExpired")));
@property (readonly) SharedLong * _Nullable lastFetched __attribute__((swift_name("lastFetched")));
@property (readonly) NSString *name __attribute__((swift_name("name")));
@property (readonly) int32_t seriesCount __attribute__((swift_name("seriesCount")));
@property (readonly) SharedInt * _Nullable seriesLibraryId __attribute__((swift_name("seriesLibraryId")));
@property (readonly) NSString *serverUrl __attribute__((swift_name("serverUrl")));
@property (readonly) NSString *username __attribute__((swift_name("username")));
@property (readonly) int32_t vodCount __attribute__((swift_name("vodCount")));
@property (readonly) SharedInt * _Nullable vodLibraryId __attribute__((swift_name("vodLibraryId")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KoinModuleKt")))
@interface SharedKoinModuleKt : SharedBase
+ (void)doInitKoinExtraModules:(NSArray<SharedKoin_coreModule *> *)extraModules appConfig:(void (^)(SharedKoin_coreKoinApplication *))appConfig __attribute__((swift_name("doInitKoin(extraModules:appConfig:)")));
@property (class, readonly) SharedKoin_coreModule *sharedModule __attribute__((swift_name("sharedModule")));
@end

__attribute__((swift_name("KotlinRuntimeException")))
@interface SharedKotlinRuntimeException : SharedKotlinException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("KotlinIllegalStateException")))
@interface SharedKotlinIllegalStateException : SharedKotlinRuntimeException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.4")
*/
__attribute__((swift_name("KotlinCancellationException")))
@interface SharedKotlinCancellationException : SharedKotlinIllegalStateException
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (instancetype)initWithMessage:(NSString * _Nullable)message __attribute__((swift_name("init(message:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithCause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(cause:)"))) __attribute__((objc_designated_initializer));
- (instancetype)initWithMessage:(NSString * _Nullable)message cause:(SharedKotlinThrowable * _Nullable)cause __attribute__((swift_name("init(message:cause:)"))) __attribute__((objc_designated_initializer));
@end

__attribute__((swift_name("Kotlinx_serialization_coreEncoder")))
@protocol SharedKotlinx_serialization_coreEncoder
@required
- (id<SharedKotlinx_serialization_coreCompositeEncoder>)beginCollectionDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor collectionSize:(int32_t)collectionSize __attribute__((swift_name("beginCollection(descriptor:collectionSize:)")));
- (id<SharedKotlinx_serialization_coreCompositeEncoder>)beginStructureDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (void)encodeBooleanValue:(BOOL)value __attribute__((swift_name("encodeBoolean(value:)")));
- (void)encodeByteValue:(int8_t)value __attribute__((swift_name("encodeByte(value:)")));
- (void)encodeCharValue:(unichar)value __attribute__((swift_name("encodeChar(value:)")));
- (void)encodeDoubleValue:(double)value __attribute__((swift_name("encodeDouble(value:)")));
- (void)encodeEnumEnumDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)enumDescriptor index:(int32_t)index __attribute__((swift_name("encodeEnum(enumDescriptor:index:)")));
- (void)encodeFloatValue:(float)value __attribute__((swift_name("encodeFloat(value:)")));
- (id<SharedKotlinx_serialization_coreEncoder>)encodeInlineDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("encodeInline(descriptor:)")));
- (void)encodeIntValue:(int32_t)value __attribute__((swift_name("encodeInt(value:)")));
- (void)encodeLongValue:(int64_t)value __attribute__((swift_name("encodeLong(value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNotNullMark __attribute__((swift_name("encodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNull __attribute__((swift_name("encodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableValueSerializer:(id<SharedKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableValue(serializer:value:)")));
- (void)encodeSerializableValueSerializer:(id<SharedKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableValue(serializer:value:)")));
- (void)encodeShortValue:(int16_t)value __attribute__((swift_name("encodeShort(value:)")));
- (void)encodeStringValue:(NSString *)value __attribute__((swift_name("encodeString(value:)")));
@property (readonly) SharedKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerialDescriptor")))
@protocol SharedKotlinx_serialization_coreSerialDescriptor
@required

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSArray<id<SharedKotlinAnnotation>> *)getElementAnnotationsIndex:(int32_t)index __attribute__((swift_name("getElementAnnotations(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<SharedKotlinx_serialization_coreSerialDescriptor>)getElementDescriptorIndex:(int32_t)index __attribute__((swift_name("getElementDescriptor(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (int32_t)getElementIndexName:(NSString *)name __attribute__((swift_name("getElementIndex(name:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (NSString *)getElementNameIndex:(int32_t)index __attribute__((swift_name("getElementName(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)isElementOptionalIndex:(int32_t)index __attribute__((swift_name("isElementOptional(index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSArray<id<SharedKotlinAnnotation>> *annotations __attribute__((swift_name("annotations")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) int32_t elementsCount __attribute__((swift_name("elementsCount")));
@property (readonly) BOOL isInline __attribute__((swift_name("isInline")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) BOOL isNullable __attribute__((swift_name("isNullable")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) SharedKotlinx_serialization_coreSerialKind *kind __attribute__((swift_name("kind")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
@property (readonly) NSString *serialName __attribute__((swift_name("serialName")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreDecoder")))
@protocol SharedKotlinx_serialization_coreDecoder
@required
- (id<SharedKotlinx_serialization_coreCompositeDecoder>)beginStructureDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("beginStructure(descriptor:)")));
- (BOOL)decodeBoolean __attribute__((swift_name("decodeBoolean()")));
- (int8_t)decodeByte __attribute__((swift_name("decodeByte()")));
- (unichar)decodeChar __attribute__((swift_name("decodeChar()")));
- (double)decodeDouble __attribute__((swift_name("decodeDouble()")));
- (int32_t)decodeEnumEnumDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)enumDescriptor __attribute__((swift_name("decodeEnum(enumDescriptor:)")));
- (float)decodeFloat __attribute__((swift_name("decodeFloat()")));
- (id<SharedKotlinx_serialization_coreDecoder>)decodeInlineDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeInline(descriptor:)")));
- (int32_t)decodeInt __attribute__((swift_name("decodeInt()")));
- (int64_t)decodeLong __attribute__((swift_name("decodeLong()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeNotNullMark __attribute__((swift_name("decodeNotNullMark()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (SharedKotlinNothing * _Nullable)decodeNull __attribute__((swift_name("decodeNull()")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableValueDeserializer:(id<SharedKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeNullableSerializableValue(deserializer:)")));
- (id _Nullable)decodeSerializableValueDeserializer:(id<SharedKotlinx_serialization_coreDeserializationStrategy>)deserializer __attribute__((swift_name("decodeSerializableValue(deserializer:)")));
- (int16_t)decodeShort __attribute__((swift_name("decodeShort()")));
- (NSString *)decodeString __attribute__((swift_name("decodeString()")));
@property (readonly) SharedKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinArray")))
@interface SharedKotlinArray<T> : SharedBase
+ (instancetype)arrayWithSize:(int32_t)size init:(T _Nullable (^)(SharedInt *))init __attribute__((swift_name("init(size:init:)")));
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (T _Nullable)getIndex:(int32_t)index __attribute__((swift_name("get(index:)")));
- (id<SharedKotlinIterator>)iterator __attribute__((swift_name("iterator()")));
- (void)setIndex:(int32_t)index value:(T _Nullable)value __attribute__((swift_name("set(index:value:)")));
@property (readonly) int32_t size __attribute__((swift_name("size")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_httpHttpMethod")))
@interface SharedKtor_httpHttpMethod : SharedBase
- (instancetype)initWithValue:(NSString *)value __attribute__((swift_name("init(value:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedKtor_httpHttpMethodCompanion *companion __attribute__((swift_name("companion")));
- (SharedKtor_httpHttpMethod *)doCopyValue:(NSString *)value __attribute__((swift_name("doCopy(value:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) NSString *value __attribute__((swift_name("value")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreFlow")))
@protocol SharedKotlinx_coroutines_coreFlow
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)collectCollector:(id<SharedKotlinx_coroutines_coreFlowCollector>)collector completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("collect(collector:completionHandler:)")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreSharedFlow")))
@protocol SharedKotlinx_coroutines_coreSharedFlow <SharedKotlinx_coroutines_coreFlow>
@required
@property (readonly) NSArray<id> *replayCache __attribute__((swift_name("replayCache")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreStateFlow")))
@protocol SharedKotlinx_coroutines_coreStateFlow <SharedKotlinx_coroutines_coreSharedFlow>
@required
@property (readonly) id _Nullable value_ __attribute__((swift_name("value_")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinEnumCompanion")))
@interface SharedKotlinEnumCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedKotlinEnumCompanion *shared __attribute__((swift_name("shared")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinPair")))
@interface SharedKotlinPair<__covariant A, __covariant B> : SharedBase
- (instancetype)initWithFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("init(first:second:)"))) __attribute__((objc_designated_initializer));
- (SharedKotlinPair<A, B> *)doCopyFirst:(A _Nullable)first second:(B _Nullable)second __attribute__((swift_name("doCopy(first:second:)")));
- (BOOL)equalsOther:(id _Nullable)other __attribute__((swift_name("equals(other:)")));
- (int32_t)hashCode __attribute__((swift_name("hashCode()")));
- (NSString *)toString __attribute__((swift_name("toString()")));
@property (readonly) A _Nullable first __attribute__((swift_name("first")));
@property (readonly) B _Nullable second __attribute__((swift_name("second")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreModule")))
@interface SharedKoin_coreModule : SharedBase
- (instancetype)initWith_createdAtStart:(BOOL)_createdAtStart __attribute__((swift_name("init(_createdAtStart:)"))) __attribute__((objc_designated_initializer));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (SharedKoin_coreKoinDefinition<id> *)factoryQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier definition:(id _Nullable (^)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *))definition __attribute__((swift_name("factory(qualifier:definition:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (void)includesModule:(SharedKotlinArray<SharedKoin_coreModule *> *)module __attribute__((swift_name("includes(module:)")));
- (void)includesModule_:(id)module __attribute__((swift_name("includes(module_:)")));
- (void)indexPrimaryTypeInstanceFactory:(SharedKoin_coreInstanceFactory<id> *)instanceFactory __attribute__((swift_name("indexPrimaryType(instanceFactory:)")));
- (void)indexSecondaryTypesInstanceFactory:(SharedKoin_coreInstanceFactory<id> *)instanceFactory __attribute__((swift_name("indexSecondaryTypes(instanceFactory:)")));
- (NSArray<SharedKoin_coreModule *> *)plusModules:(NSArray<SharedKoin_coreModule *> *)modules __attribute__((swift_name("plus(modules:)")));
- (NSArray<SharedKoin_coreModule *> *)plusModule:(SharedKoin_coreModule *)module __attribute__((swift_name("plus(module:)")));
- (void)prepareForCreationAtStartInstanceFactory:(SharedKoin_coreSingleInstanceFactory<id> *)instanceFactory __attribute__((swift_name("prepareForCreationAtStart(instanceFactory:)")));
- (void)scopeScopeSet:(void (^)(SharedKoin_coreScopeDSL *))scopeSet __attribute__((swift_name("scope(scopeSet:)")));
- (void)scopeQualifier:(id<SharedKoin_coreQualifier>)qualifier scopeSet:(void (^)(SharedKoin_coreScopeDSL *))scopeSet __attribute__((swift_name("scope(qualifier:scopeSet:)")));
- (SharedKoin_coreKoinDefinition<id> *)singleQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier createdAtStart:(BOOL)createdAtStart definition:(id _Nullable (^)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *))definition __attribute__((swift_name("single(qualifier:createdAtStart:definition:)")));
@property (readonly) SharedMutableSet<SharedKoin_coreSingleInstanceFactory<id> *> *eagerInstances __attribute__((swift_name("eagerInstances")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) NSMutableArray<SharedKoin_coreModule *> *includedModules __attribute__((swift_name("includedModules")));
@property (readonly) BOOL isLoaded __attribute__((swift_name("isLoaded")));
@property (readonly) SharedMutableDictionary<NSString *, SharedKoin_coreInstanceFactory<id> *> *mappings __attribute__((swift_name("mappings")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreKoinApplication")))
@interface SharedKoin_coreKoinApplication : SharedBase
@property (class, readonly, getter=companion) SharedKoin_coreKoinApplicationCompanion *companion __attribute__((swift_name("companion")));
- (void)allowOverrideOverride:(BOOL)override __attribute__((swift_name("allowOverride(override:)")));
- (void)close __attribute__((swift_name("close()")));
- (void)createEagerInstances __attribute__((swift_name("createEagerInstances()")));
- (SharedKoin_coreKoinApplication *)loggerLogger:(SharedKoin_coreLogger *)logger __attribute__((swift_name("logger(logger:)")));
- (SharedKoin_coreKoinApplication *)modulesModules:(SharedKotlinArray<SharedKoin_coreModule *> *)modules __attribute__((swift_name("modules(modules:)")));
- (SharedKoin_coreKoinApplication *)modulesModules_:(NSArray<SharedKoin_coreModule *> *)modules __attribute__((swift_name("modules(modules_:)")));
- (SharedKoin_coreKoinApplication *)modulesModules__:(SharedKoin_coreModule *)modules __attribute__((swift_name("modules(modules__:)")));
- (SharedKoin_coreKoinApplication *)printLoggerLevel:(SharedKoin_coreLevel *)level __attribute__((swift_name("printLogger(level:)")));
- (SharedKoin_coreKoinApplication *)propertiesValues:(NSDictionary<NSString *, id> *)values __attribute__((swift_name("properties(values:)")));
@property (readonly) SharedKoin_coreKoin *koin __attribute__((swift_name("koin")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeEncoder")))
@protocol SharedKotlinx_serialization_coreCompositeEncoder
@required
- (void)encodeBooleanElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(BOOL)value __attribute__((swift_name("encodeBooleanElement(descriptor:index:value:)")));
- (void)encodeByteElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int8_t)value __attribute__((swift_name("encodeByteElement(descriptor:index:value:)")));
- (void)encodeCharElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(unichar)value __attribute__((swift_name("encodeCharElement(descriptor:index:value:)")));
- (void)encodeDoubleElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(double)value __attribute__((swift_name("encodeDoubleElement(descriptor:index:value:)")));
- (void)encodeFloatElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(float)value __attribute__((swift_name("encodeFloatElement(descriptor:index:value:)")));
- (id<SharedKotlinx_serialization_coreEncoder>)encodeInlineElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("encodeInlineElement(descriptor:index:)")));
- (void)encodeIntElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int32_t)value __attribute__((swift_name("encodeIntElement(descriptor:index:value:)")));
- (void)encodeLongElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int64_t)value __attribute__((swift_name("encodeLongElement(descriptor:index:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)encodeNullableSerializableElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<SharedKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeNullableSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeSerializableElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index serializer:(id<SharedKotlinx_serialization_coreSerializationStrategy>)serializer value:(id _Nullable)value __attribute__((swift_name("encodeSerializableElement(descriptor:index:serializer:value:)")));
- (void)encodeShortElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(int16_t)value __attribute__((swift_name("encodeShortElement(descriptor:index:value:)")));
- (void)encodeStringElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index value:(NSString *)value __attribute__((swift_name("encodeStringElement(descriptor:index:value:)")));
- (void)endStructureDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)shouldEncodeElementDefaultDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("shouldEncodeElementDefault(descriptor:index:)")));
@property (readonly) SharedKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreSerializersModule")))
@interface SharedKotlinx_serialization_coreSerializersModule : SharedBase

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (void)dumpToCollector:(id<SharedKotlinx_serialization_coreSerializersModuleCollector>)collector __attribute__((swift_name("dumpTo(collector:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<SharedKotlinx_serialization_coreKSerializer> _Nullable)getContextualKClass:(id<SharedKotlinKClass>)kClass typeArgumentsSerializers:(NSArray<id<SharedKotlinx_serialization_coreKSerializer>> *)typeArgumentsSerializers __attribute__((swift_name("getContextual(kClass:typeArgumentsSerializers:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<SharedKotlinx_serialization_coreSerializationStrategy> _Nullable)getPolymorphicBaseClass:(id<SharedKotlinKClass>)baseClass value:(id)value __attribute__((swift_name("getPolymorphic(baseClass:value:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id<SharedKotlinx_serialization_coreDeserializationStrategy> _Nullable)getPolymorphicBaseClass:(id<SharedKotlinKClass>)baseClass serializedClassName:(NSString * _Nullable)serializedClassName __attribute__((swift_name("getPolymorphic(baseClass:serializedClassName:)")));
@end

__attribute__((swift_name("KotlinAnnotation")))
@protocol SharedKotlinAnnotation
@required
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerialKind")))
@interface SharedKotlinx_serialization_coreSerialKind : SharedBase
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@end

__attribute__((swift_name("Kotlinx_serialization_coreCompositeDecoder")))
@protocol SharedKotlinx_serialization_coreCompositeDecoder
@required
- (BOOL)decodeBooleanElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeBooleanElement(descriptor:index:)")));
- (int8_t)decodeByteElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeByteElement(descriptor:index:)")));
- (unichar)decodeCharElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeCharElement(descriptor:index:)")));
- (int32_t)decodeCollectionSizeDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeCollectionSize(descriptor:)")));
- (double)decodeDoubleElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeDoubleElement(descriptor:index:)")));
- (int32_t)decodeElementIndexDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("decodeElementIndex(descriptor:)")));
- (float)decodeFloatElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeFloatElement(descriptor:index:)")));
- (id<SharedKotlinx_serialization_coreDecoder>)decodeInlineElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeInlineElement(descriptor:index:)")));
- (int32_t)decodeIntElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeIntElement(descriptor:index:)")));
- (int64_t)decodeLongElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeLongElement(descriptor:index:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (id _Nullable)decodeNullableSerializableElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<SharedKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeNullableSerializableElement(descriptor:index:deserializer:previousValue:)")));

/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
- (BOOL)decodeSequentially __attribute__((swift_name("decodeSequentially()")));
- (id _Nullable)decodeSerializableElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index deserializer:(id<SharedKotlinx_serialization_coreDeserializationStrategy>)deserializer previousValue:(id _Nullable)previousValue __attribute__((swift_name("decodeSerializableElement(descriptor:index:deserializer:previousValue:)")));
- (int16_t)decodeShortElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeShortElement(descriptor:index:)")));
- (NSString *)decodeStringElementDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor index:(int32_t)index __attribute__((swift_name("decodeStringElement(descriptor:index:)")));
- (void)endStructureDescriptor:(id<SharedKotlinx_serialization_coreSerialDescriptor>)descriptor __attribute__((swift_name("endStructure(descriptor:)")));
@property (readonly) SharedKotlinx_serialization_coreSerializersModule *serializersModule __attribute__((swift_name("serializersModule")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinNothing")))
@interface SharedKotlinNothing : SharedBase
@end

__attribute__((swift_name("KotlinIterator")))
@protocol SharedKotlinIterator
@required
- (BOOL)hasNext __attribute__((swift_name("hasNext()")));
- (id _Nullable)next __attribute__((swift_name("next()")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Ktor_httpHttpMethod.Companion")))
@interface SharedKtor_httpHttpMethodCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedKtor_httpHttpMethodCompanion *shared __attribute__((swift_name("shared")));
- (SharedKtor_httpHttpMethod *)parseMethod:(NSString *)method __attribute__((swift_name("parse(method:)")));
@property (readonly) NSArray<SharedKtor_httpHttpMethod *> *DefaultMethods __attribute__((swift_name("DefaultMethods")));
@property (readonly) SharedKtor_httpHttpMethod *Delete __attribute__((swift_name("Delete")));
@property (readonly) SharedKtor_httpHttpMethod *Get __attribute__((swift_name("Get")));
@property (readonly) SharedKtor_httpHttpMethod *Head __attribute__((swift_name("Head")));
@property (readonly) SharedKtor_httpHttpMethod *Options __attribute__((swift_name("Options")));
@property (readonly) SharedKtor_httpHttpMethod *Patch __attribute__((swift_name("Patch")));
@property (readonly) SharedKtor_httpHttpMethod *Post __attribute__((swift_name("Post")));
@property (readonly) SharedKtor_httpHttpMethod *Put __attribute__((swift_name("Put")));
@end

__attribute__((swift_name("Kotlinx_coroutines_coreFlowCollector")))
@protocol SharedKotlinx_coroutines_coreFlowCollector
@required

/**
 * @note This method converts instances of CancellationException to errors.
 * Other uncaught Kotlin exceptions are fatal.
*/
- (void)emitValue:(id _Nullable)value completionHandler:(void (^)(NSError * _Nullable))completionHandler __attribute__((swift_name("emit(value:completionHandler:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreKoinDefinition")))
@interface SharedKoin_coreKoinDefinition<R> : SharedBase
- (instancetype)initWithModule:(SharedKoin_coreModule *)module factory:(SharedKoin_coreInstanceFactory<R> *)factory __attribute__((swift_name("init(module:factory:)"))) __attribute__((objc_designated_initializer));
- (SharedKoin_coreKoinDefinition<R> *)doCopyModule:(SharedKoin_coreModule *)module factory:(SharedKoin_coreInstanceFactory<R> *)factory __attribute__((swift_name("doCopy(module:factory:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) SharedKoin_coreInstanceFactory<R> *factory __attribute__((swift_name("factory")));
@property (readonly) SharedKoin_coreModule *module __attribute__((swift_name("module")));
@end

__attribute__((swift_name("Koin_coreQualifier")))
@protocol SharedKoin_coreQualifier
@required
@property (readonly) NSString *value_ __attribute__((swift_name("value_")));
@end

__attribute__((swift_name("Koin_coreLockable")))
@interface SharedKoin_coreLockable : SharedBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreScope")))
@interface SharedKoin_coreScope : SharedKoin_coreLockable
- (instancetype)initWithScopeQualifier:(id<SharedKoin_coreQualifier>)scopeQualifier id:(NSString *)id isRoot:(BOOL)isRoot _koin:(SharedKoin_coreKoin *)_koin __attribute__((swift_name("init(scopeQualifier:id:isRoot:_koin:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
- (void)close __attribute__((swift_name("close()")));
- (void)declareInstance:(id _Nullable)instance qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier secondaryTypes:(NSArray<id<SharedKotlinKClass>> *)secondaryTypes allowOverride:(BOOL)allowOverride holdInstance:(BOOL)holdInstance __attribute__((swift_name("declare(instance:qualifier:secondaryTypes:allowOverride:holdInstance:)")));
- (id)getQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("get(qualifier:parameters:)")));
- (id _Nullable)getClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("get(clazz:qualifier:parameters:)")));
- (NSArray<id> *)getAll __attribute__((swift_name("getAll()")));
- (NSArray<id> *)getAllClazz:(id<SharedKotlinKClass>)clazz __attribute__((swift_name("getAll(clazz:)")));
- (SharedKoin_coreKoin *)getKoin __attribute__((swift_name("getKoin()")));
- (id _Nullable)getOrNullQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("getOrNull(qualifier:parameters:)")));
- (id _Nullable)getOrNullClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("getOrNull(clazz:qualifier:parameters:)")));
- (id)getPropertyKey:(NSString *)key __attribute__((swift_name("getProperty(key:)")));
- (id)getPropertyKey:(NSString *)key defaultValue:(id)defaultValue __attribute__((swift_name("getProperty(key:defaultValue:)")));
- (id _Nullable)getPropertyOrNullKey:(NSString *)key __attribute__((swift_name("getPropertyOrNull(key:)")));
- (SharedKoin_coreScope *)getScopeScopeID:(NSString *)scopeID __attribute__((swift_name("getScope(scopeID:)")));
- (id _Nullable)getSource __attribute__((swift_name("getSource()")));
- (id _Nullable)getWithParametersClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder * _Nullable)parameters __attribute__((swift_name("getWithParameters(clazz:qualifier:parameters:)")));
- (id<SharedKotlinLazy>)injectQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier mode:(SharedKotlinLazyThreadSafetyMode *)mode parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("inject(qualifier:mode:parameters:)")));
- (id<SharedKotlinLazy>)injectOrNullQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier mode:(SharedKotlinLazyThreadSafetyMode *)mode parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("injectOrNull(qualifier:mode:parameters:)")));
- (BOOL)isNotClosed __attribute__((swift_name("isNotClosed()")));
- (void)linkToScopes:(SharedKotlinArray<SharedKoin_coreScope *> *)scopes __attribute__((swift_name("linkTo(scopes:)")));
- (void)registerCallbackCallback:(id<SharedKoin_coreScopeCallback>)callback __attribute__((swift_name("registerCallback(callback:)")));
- (NSString *)description __attribute__((swift_name("description()")));
- (void)unlinkScopes:(SharedKotlinArray<SharedKoin_coreScope *> *)scopes __attribute__((swift_name("unlink(scopes:)")));
@property (readonly) BOOL closed __attribute__((swift_name("closed")));
@property (readonly) NSString *id __attribute__((swift_name("id")));
@property (readonly) BOOL isRoot __attribute__((swift_name("isRoot")));
@property (readonly) SharedKoin_coreLogger *logger __attribute__((swift_name("logger")));
@property (readonly) id<SharedKoin_coreQualifier> scopeQualifier __attribute__((swift_name("scopeQualifier")));
@property id _Nullable sourceValue __attribute__((swift_name("sourceValue")));
@end

__attribute__((swift_name("Koin_coreParametersHolder")))
@interface SharedKoin_coreParametersHolder : SharedBase
- (instancetype)initWith_values:(NSMutableArray<id> *)_values useIndexedValues:(SharedBoolean * _Nullable)useIndexedValues __attribute__((swift_name("init(_values:useIndexedValues:)"))) __attribute__((objc_designated_initializer));
- (SharedKoin_coreParametersHolder *)addValue:(id)value __attribute__((swift_name("add(value:)")));
- (id _Nullable)component1 __attribute__((swift_name("component1()")));
- (id _Nullable)component2 __attribute__((swift_name("component2()")));
- (id _Nullable)component3 __attribute__((swift_name("component3()")));
- (id _Nullable)component4 __attribute__((swift_name("component4()")));
- (id _Nullable)component5 __attribute__((swift_name("component5()")));
- (id _Nullable)elementAtI:(int32_t)i clazz:(id<SharedKotlinKClass>)clazz __attribute__((swift_name("elementAt(i:clazz:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (id)get __attribute__((swift_name("get()")));
- (id _Nullable)getI:(int32_t)i __attribute__((swift_name("get(i:)")));
- (id _Nullable)getOrNull __attribute__((swift_name("getOrNull()")));
- (id _Nullable)getOrNullClazz:(id<SharedKotlinKClass>)clazz __attribute__((swift_name("getOrNull(clazz:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (SharedKoin_coreParametersHolder *)insertIndex:(int32_t)index value:(id)value __attribute__((swift_name("insert(index:value:)")));
- (BOOL)isEmpty __attribute__((swift_name("isEmpty()")));
- (BOOL)isNotEmpty __attribute__((swift_name("isNotEmpty()")));
- (void)setI:(int32_t)i t:(id _Nullable)t __attribute__((swift_name("set(i:t:)")));
- (int32_t)size __attribute__((swift_name("size()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property int32_t index __attribute__((swift_name("index")));
@property (readonly) SharedBoolean * _Nullable useIndexedValues __attribute__((swift_name("useIndexedValues")));
@property (readonly) NSArray<id> *values __attribute__((swift_name("values")));
@end

__attribute__((swift_name("Koin_coreInstanceFactory")))
@interface SharedKoin_coreInstanceFactory<T> : SharedKoin_coreLockable
- (instancetype)initWithBeanDefinition:(SharedKoin_coreBeanDefinition<T> *)beanDefinition __attribute__((swift_name("init(beanDefinition:)"))) __attribute__((objc_designated_initializer));
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
+ (instancetype)new __attribute__((unavailable));
@property (class, readonly, getter=companion) SharedKoin_coreInstanceFactoryCompanion *companion __attribute__((swift_name("companion")));
- (T _Nullable)createContext:(SharedKoin_coreResolutionContext *)context __attribute__((swift_name("create(context:)")));
- (void)dropScope:(SharedKoin_coreScope * _Nullable)scope __attribute__((swift_name("drop(scope:)")));
- (void)dropAll __attribute__((swift_name("dropAll()")));
- (T _Nullable)getContext:(SharedKoin_coreResolutionContext *)context __attribute__((swift_name("get(context:)")));
- (BOOL)isCreatedContext:(SharedKoin_coreResolutionContext * _Nullable)context __attribute__((swift_name("isCreated(context:)")));
@property (readonly) SharedKoin_coreBeanDefinition<T> *beanDefinition __attribute__((swift_name("beanDefinition")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreSingleInstanceFactory")))
@interface SharedKoin_coreSingleInstanceFactory<T> : SharedKoin_coreInstanceFactory<T>
- (instancetype)initWithBeanDefinition:(SharedKoin_coreBeanDefinition<T> *)beanDefinition __attribute__((swift_name("init(beanDefinition:)"))) __attribute__((objc_designated_initializer));
- (T _Nullable)createContext:(SharedKoin_coreResolutionContext *)context __attribute__((swift_name("create(context:)")));
- (void)dropScope:(SharedKoin_coreScope * _Nullable)scope __attribute__((swift_name("drop(scope:)")));
- (void)dropAll __attribute__((swift_name("dropAll()")));
- (T _Nullable)getContext:(SharedKoin_coreResolutionContext *)context __attribute__((swift_name("get(context:)")));
- (BOOL)isCreatedContext:(SharedKoin_coreResolutionContext * _Nullable)context __attribute__((swift_name("isCreated(context:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreScopeDSL")))
@interface SharedKoin_coreScopeDSL : SharedBase
- (instancetype)initWithScopeQualifier:(id<SharedKoin_coreQualifier>)scopeQualifier module:(SharedKoin_coreModule *)module __attribute__((swift_name("init(scopeQualifier:module:)"))) __attribute__((objc_designated_initializer));
- (SharedKoin_coreKoinDefinition<id> *)factoryQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier definition:(id _Nullable (^)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *))definition __attribute__((swift_name("factory(qualifier:definition:)")));
- (SharedKoin_coreKoinDefinition<id> *)scopedQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier definition:(id _Nullable (^)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *))definition __attribute__((swift_name("scoped(qualifier:definition:)")));
@property (readonly) SharedKoin_coreModule *module __attribute__((swift_name("module")));
@property (readonly) id<SharedKoin_coreQualifier> scopeQualifier __attribute__((swift_name("scopeQualifier")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreKoinApplication.Companion")))
@interface SharedKoin_coreKoinApplicationCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedKoin_coreKoinApplicationCompanion *shared __attribute__((swift_name("shared")));
- (SharedKoin_coreKoinApplication *)doInit __attribute__((swift_name("doInit()")));
@end

__attribute__((swift_name("Koin_coreLogger")))
@interface SharedKoin_coreLogger : SharedBase
- (instancetype)initWithLevel:(SharedKoin_coreLevel *)level __attribute__((swift_name("init(level:)"))) __attribute__((objc_designated_initializer));
- (void)debugMsg:(NSString *)msg __attribute__((swift_name("debug(msg:)")));
- (void)displayLevel:(SharedKoin_coreLevel *)level msg:(NSString *)msg __attribute__((swift_name("display(level:msg:)")));
- (void)errorMsg:(NSString *)msg __attribute__((swift_name("error(msg:)")));
- (void)infoMsg:(NSString *)msg __attribute__((swift_name("info(msg:)")));
- (BOOL)isAtLvl:(SharedKoin_coreLevel *)lvl __attribute__((swift_name("isAt(lvl:)")));
- (void)logLvl:(SharedKoin_coreLevel *)lvl msg:(NSString *(^)(void))msg __attribute__((swift_name("log(lvl:msg:)")));
- (void)logLvl:(SharedKoin_coreLevel *)lvl msg_:(NSString *)msg __attribute__((swift_name("log(lvl:msg_:)")));
- (void)warnMsg:(NSString *)msg __attribute__((swift_name("warn(msg:)")));
@property SharedKoin_coreLevel *level __attribute__((swift_name("level")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreLevel")))
@interface SharedKoin_coreLevel : SharedKotlinEnum<SharedKoin_coreLevel *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SharedKoin_coreLevel *debug __attribute__((swift_name("debug")));
@property (class, readonly) SharedKoin_coreLevel *info __attribute__((swift_name("info")));
@property (class, readonly) SharedKoin_coreLevel *warning __attribute__((swift_name("warning")));
@property (class, readonly) SharedKoin_coreLevel *error __attribute__((swift_name("error")));
@property (class, readonly) SharedKoin_coreLevel *none __attribute__((swift_name("none")));
+ (SharedKotlinArray<SharedKoin_coreLevel *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedKoin_coreLevel *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreKoin")))
@interface SharedKoin_coreKoin : SharedBase
- (instancetype)init __attribute__((swift_name("init()"))) __attribute__((objc_designated_initializer));
+ (instancetype)new __attribute__((availability(swift, unavailable, message="use object initializers instead")));
- (void)close __attribute__((swift_name("close()")));
- (void)createEagerInstances __attribute__((swift_name("createEagerInstances()")));
- (SharedKoin_coreScope *)createScopeT:(id<SharedKoin_coreKoinScopeComponent>)t __attribute__((swift_name("createScope(t:)")));
- (SharedKoin_coreScope *)createScopeScopeId:(NSString *)scopeId __attribute__((swift_name("createScope(scopeId:)")));
- (SharedKoin_coreScope *)createScopeScopeId:(NSString *)scopeId source:(id _Nullable)source __attribute__((swift_name("createScope(scopeId:source:)")));
- (SharedKoin_coreScope *)createScopeScopeId:(NSString *)scopeId qualifier:(id<SharedKoin_coreQualifier>)qualifier source:(id _Nullable)source __attribute__((swift_name("createScope(scopeId:qualifier:source:)")));
- (void)declareInstance:(id _Nullable)instance qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier secondaryTypes:(NSArray<id<SharedKotlinKClass>> *)secondaryTypes allowOverride:(BOOL)allowOverride __attribute__((swift_name("declare(instance:qualifier:secondaryTypes:allowOverride:)")));
- (void)deletePropertyKey:(NSString *)key __attribute__((swift_name("deleteProperty(key:)")));
- (void)deleteScopeScopeId:(NSString *)scopeId __attribute__((swift_name("deleteScope(scopeId:)")));
- (id)getQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("get(qualifier:parameters:)")));
- (id _Nullable)getClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("get(clazz:qualifier:parameters:)")));
- (NSArray<id> *)getAll __attribute__((swift_name("getAll()")));
- (SharedKoin_coreScope *)getOrCreateScopeScopeId:(NSString *)scopeId __attribute__((swift_name("getOrCreateScope(scopeId:)")));
- (SharedKoin_coreScope *)getOrCreateScopeScopeId:(NSString *)scopeId qualifier:(id<SharedKoin_coreQualifier>)qualifier source:(id _Nullable)source __attribute__((swift_name("getOrCreateScope(scopeId:qualifier:source:)")));
- (id _Nullable)getOrNullQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("getOrNull(qualifier:parameters:)")));
- (id _Nullable)getOrNullClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("getOrNull(clazz:qualifier:parameters:)")));
- (id _Nullable)getPropertyKey:(NSString *)key __attribute__((swift_name("getProperty(key:)")));
- (id)getPropertyKey:(NSString *)key defaultValue:(id)defaultValue __attribute__((swift_name("getProperty(key:defaultValue:)")));
- (SharedKoin_coreScope *)getScopeScopeId:(NSString *)scopeId __attribute__((swift_name("getScope(scopeId:)")));
- (SharedKoin_coreScope * _Nullable)getScopeOrNullScopeId:(NSString *)scopeId __attribute__((swift_name("getScopeOrNull(scopeId:)")));
- (id<SharedKotlinLazy>)injectQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier mode:(SharedKotlinLazyThreadSafetyMode *)mode parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("inject(qualifier:mode:parameters:)")));
- (id<SharedKotlinLazy>)injectOrNullQualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier mode:(SharedKotlinLazyThreadSafetyMode *)mode parameters:(SharedKoin_coreParametersHolder *(^ _Nullable)(void))parameters __attribute__((swift_name("injectOrNull(qualifier:mode:parameters:)")));
- (void)loadModulesModules:(NSArray<SharedKoin_coreModule *> *)modules allowOverride:(BOOL)allowOverride createEagerInstances:(BOOL)createEagerInstances __attribute__((swift_name("loadModules(modules:allowOverride:createEagerInstances:)")));
- (void)setPropertyKey:(NSString *)key value:(id)value __attribute__((swift_name("setProperty(key:value:)")));
- (void)setupLoggerLogger:(SharedKoin_coreLogger *)logger __attribute__((swift_name("setupLogger(logger:)")));
- (void)unloadModulesModules:(NSArray<SharedKoin_coreModule *> *)modules __attribute__((swift_name("unloadModules(modules:)")));
@property (readonly) SharedKoin_coreExtensionManager *extensionManager __attribute__((swift_name("extensionManager")));
@property (readonly) SharedKoin_coreInstanceRegistry *instanceRegistry __attribute__((swift_name("instanceRegistry")));
@property (readonly) SharedKoin_coreLogger *logger __attribute__((swift_name("logger")));
@property (readonly) SharedKoin_corePropertyRegistry *propertyRegistry __attribute__((swift_name("propertyRegistry")));
@property (readonly) SharedKoin_coreScopeRegistry *scopeRegistry __attribute__((swift_name("scopeRegistry")));
@end


/**
 * @note annotations
 *   kotlinx.serialization.ExperimentalSerializationApi
*/
__attribute__((swift_name("Kotlinx_serialization_coreSerializersModuleCollector")))
@protocol SharedKotlinx_serialization_coreSerializersModuleCollector
@required
- (void)contextualKClass:(id<SharedKotlinKClass>)kClass provider:(id<SharedKotlinx_serialization_coreKSerializer> (^)(NSArray<id<SharedKotlinx_serialization_coreKSerializer>> *))provider __attribute__((swift_name("contextual(kClass:provider:)")));
- (void)contextualKClass:(id<SharedKotlinKClass>)kClass serializer:(id<SharedKotlinx_serialization_coreKSerializer>)serializer __attribute__((swift_name("contextual(kClass:serializer:)")));
- (void)polymorphicBaseClass:(id<SharedKotlinKClass>)baseClass actualClass:(id<SharedKotlinKClass>)actualClass actualSerializer:(id<SharedKotlinx_serialization_coreKSerializer>)actualSerializer __attribute__((swift_name("polymorphic(baseClass:actualClass:actualSerializer:)")));
- (void)polymorphicDefaultBaseClass:(id<SharedKotlinKClass>)baseClass defaultDeserializerProvider:(id<SharedKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefault(baseClass:defaultDeserializerProvider:)"))) __attribute__((deprecated("Deprecated in favor of function with more precise name: polymorphicDefaultDeserializer")));
- (void)polymorphicDefaultDeserializerBaseClass:(id<SharedKotlinKClass>)baseClass defaultDeserializerProvider:(id<SharedKotlinx_serialization_coreDeserializationStrategy> _Nullable (^)(NSString * _Nullable))defaultDeserializerProvider __attribute__((swift_name("polymorphicDefaultDeserializer(baseClass:defaultDeserializerProvider:)")));
- (void)polymorphicDefaultSerializerBaseClass:(id<SharedKotlinKClass>)baseClass defaultSerializerProvider:(id<SharedKotlinx_serialization_coreSerializationStrategy> _Nullable (^)(id))defaultSerializerProvider __attribute__((swift_name("polymorphicDefaultSerializer(baseClass:defaultSerializerProvider:)")));
@end

__attribute__((swift_name("KotlinKDeclarationContainer")))
@protocol SharedKotlinKDeclarationContainer
@required
@end

__attribute__((swift_name("KotlinKAnnotatedElement")))
@protocol SharedKotlinKAnnotatedElement
@required
@end


/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
__attribute__((swift_name("KotlinKClassifier")))
@protocol SharedKotlinKClassifier
@required
@end

__attribute__((swift_name("KotlinKClass")))
@protocol SharedKotlinKClass <SharedKotlinKDeclarationContainer, SharedKotlinKAnnotatedElement, SharedKotlinKClassifier>
@required

/**
 * @note annotations
 *   kotlin.SinceKotlin(version="1.1")
*/
- (BOOL)isInstanceValue:(id _Nullable)value __attribute__((swift_name("isInstance(value:)")));
@property (readonly) NSString * _Nullable qualifiedName __attribute__((swift_name("qualifiedName")));
@property (readonly) NSString * _Nullable simpleName __attribute__((swift_name("simpleName")));
@end

__attribute__((swift_name("KotlinLazy")))
@protocol SharedKotlinLazy
@required
- (BOOL)isInitialized __attribute__((swift_name("isInitialized()")));
@property (readonly) id _Nullable value_ __attribute__((swift_name("value_")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("KotlinLazyThreadSafetyMode")))
@interface SharedKotlinLazyThreadSafetyMode : SharedKotlinEnum<SharedKotlinLazyThreadSafetyMode *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SharedKotlinLazyThreadSafetyMode *synchronized __attribute__((swift_name("synchronized")));
@property (class, readonly) SharedKotlinLazyThreadSafetyMode *publication __attribute__((swift_name("publication")));
@property (class, readonly) SharedKotlinLazyThreadSafetyMode *none __attribute__((swift_name("none")));
+ (SharedKotlinArray<SharedKotlinLazyThreadSafetyMode *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedKotlinLazyThreadSafetyMode *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((swift_name("Koin_coreScopeCallback")))
@protocol SharedKoin_coreScopeCallback
@required
- (void)onScopeCloseScope:(SharedKoin_coreScope *)scope __attribute__((swift_name("onScopeClose(scope:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreBeanDefinition")))
@interface SharedKoin_coreBeanDefinition<T> : SharedBase
- (instancetype)initWithScopeQualifier:(id<SharedKoin_coreQualifier>)scopeQualifier primaryType:(id<SharedKotlinKClass>)primaryType qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier definition:(T _Nullable (^)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *))definition kind:(SharedKoin_coreKind *)kind secondaryTypes:(NSArray<id<SharedKotlinKClass>> *)secondaryTypes __attribute__((swift_name("init(scopeQualifier:primaryType:qualifier:definition:kind:secondaryTypes:)"))) __attribute__((objc_designated_initializer));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (BOOL)hasTypeClazz:(id<SharedKotlinKClass>)clazz __attribute__((swift_name("hasType(clazz:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (BOOL)isClazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier scopeDefinition:(id<SharedKoin_coreQualifier>)scopeDefinition __attribute__((swift_name("is(clazz:qualifier:scopeDefinition:)")));
- (NSString *)description __attribute__((swift_name("description()")));
@property SharedKoin_coreCallbacks<T> *callbacks __attribute__((swift_name("callbacks")));
@property (readonly) T _Nullable (^definition)(SharedKoin_coreScope *, SharedKoin_coreParametersHolder *) __attribute__((swift_name("definition")));
@property (readonly) SharedKoin_coreKind *kind __attribute__((swift_name("kind")));
@property (readonly) id<SharedKotlinKClass> primaryType __attribute__((swift_name("primaryType")));
@property id<SharedKoin_coreQualifier> _Nullable qualifier __attribute__((swift_name("qualifier")));
@property (readonly) id<SharedKoin_coreQualifier> scopeQualifier __attribute__((swift_name("scopeQualifier")));
@property NSArray<id<SharedKotlinKClass>> *secondaryTypes __attribute__((swift_name("secondaryTypes")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreInstanceFactoryCompanion")))
@interface SharedKoin_coreInstanceFactoryCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedKoin_coreInstanceFactoryCompanion *shared __attribute__((swift_name("shared")));
@property (readonly) NSString *ERROR_SEPARATOR __attribute__((swift_name("ERROR_SEPARATOR")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreResolutionContext")))
@interface SharedKoin_coreResolutionContext : SharedBase
- (instancetype)initWithLogger:(SharedKoin_coreLogger *)logger scope:(SharedKoin_coreScope *)scope clazz:(id<SharedKotlinKClass>)clazz qualifier:(id<SharedKoin_coreQualifier> _Nullable)qualifier parameters:(SharedKoin_coreParametersHolder * _Nullable)parameters __attribute__((swift_name("init(logger:scope:clazz:qualifier:parameters:)"))) __attribute__((objc_designated_initializer));
@property (readonly) id<SharedKotlinKClass> clazz __attribute__((swift_name("clazz")));
@property (readonly) NSString *debugTag __attribute__((swift_name("debugTag")));
@property (readonly) SharedKoin_coreLogger *logger __attribute__((swift_name("logger")));
@property (readonly) SharedKoin_coreParametersHolder * _Nullable parameters __attribute__((swift_name("parameters")));
@property (readonly) id<SharedKoin_coreQualifier> _Nullable qualifier __attribute__((swift_name("qualifier")));
@property (readonly) SharedKoin_coreScope *scope __attribute__((swift_name("scope")));
@end

__attribute__((swift_name("Koin_coreKoinComponent")))
@protocol SharedKoin_coreKoinComponent
@required
- (SharedKoin_coreKoin *)getKoin __attribute__((swift_name("getKoin()")));
@end

__attribute__((swift_name("Koin_coreKoinScopeComponent")))
@protocol SharedKoin_coreKoinScopeComponent <SharedKoin_coreKoinComponent>
@required
@property (readonly) SharedKoin_coreScope *scope __attribute__((swift_name("scope")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreExtensionManager")))
@interface SharedKoin_coreExtensionManager : SharedBase
- (instancetype)initWith_koin:(SharedKoin_coreKoin *)_koin __attribute__((swift_name("init(_koin:)"))) __attribute__((objc_designated_initializer));
- (void)close __attribute__((swift_name("close()")));
- (id<SharedKoin_coreKoinExtension>)getExtensionId:(NSString *)id __attribute__((swift_name("getExtension(id:)")));
- (id<SharedKoin_coreKoinExtension> _Nullable)getExtensionOrNullId:(NSString *)id __attribute__((swift_name("getExtensionOrNull(id:)")));
- (void)registerExtensionId:(NSString *)id extension:(id<SharedKoin_coreKoinExtension>)extension __attribute__((swift_name("registerExtension(id:extension:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreInstanceRegistry")))
@interface SharedKoin_coreInstanceRegistry : SharedBase
- (instancetype)initWith_koin:(SharedKoin_coreKoin *)_koin __attribute__((swift_name("init(_koin:)"))) __attribute__((objc_designated_initializer));
- (void)saveMappingAllowOverride:(BOOL)allowOverride mapping:(NSString *)mapping factory:(SharedKoin_coreInstanceFactory<id> *)factory logWarning:(BOOL)logWarning __attribute__((swift_name("saveMapping(allowOverride:mapping:factory:logWarning:)")));
- (int32_t)size __attribute__((swift_name("size()")));
@property (readonly) SharedKoin_coreKoin *_koin __attribute__((swift_name("_koin")));
@property (readonly) NSDictionary<NSString *, SharedKoin_coreInstanceFactory<id> *> *instances __attribute__((swift_name("instances")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_corePropertyRegistry")))
@interface SharedKoin_corePropertyRegistry : SharedBase
- (instancetype)initWith_koin:(SharedKoin_coreKoin *)_koin __attribute__((swift_name("init(_koin:)"))) __attribute__((objc_designated_initializer));
- (void)close __attribute__((swift_name("close()")));
- (void)deletePropertyKey:(NSString *)key __attribute__((swift_name("deleteProperty(key:)")));
- (id _Nullable)getPropertyKey:(NSString *)key __attribute__((swift_name("getProperty(key:)")));
- (void)savePropertiesProperties:(NSDictionary<NSString *, id> *)properties __attribute__((swift_name("saveProperties(properties:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreScopeRegistry")))
@interface SharedKoin_coreScopeRegistry : SharedBase
- (instancetype)initWith_koin:(SharedKoin_coreKoin *)_koin __attribute__((swift_name("init(_koin:)"))) __attribute__((objc_designated_initializer));
@property (class, readonly, getter=companion) SharedKoin_coreScopeRegistryCompanion *companion __attribute__((swift_name("companion")));
- (void)loadScopesModules:(NSSet<SharedKoin_coreModule *> *)modules __attribute__((swift_name("loadScopes(modules:)")));
@property (readonly) SharedKoin_coreScope *rootScope __attribute__((swift_name("rootScope")));
@property (readonly) NSSet<id<SharedKoin_coreQualifier>> *scopeDefinitions __attribute__((swift_name("scopeDefinitions")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreKind")))
@interface SharedKoin_coreKind : SharedKotlinEnum<SharedKoin_coreKind *>
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
- (instancetype)initWithName:(NSString *)name ordinal:(int32_t)ordinal __attribute__((swift_name("init(name:ordinal:)"))) __attribute__((objc_designated_initializer)) __attribute__((unavailable));
@property (class, readonly) SharedKoin_coreKind *singleton __attribute__((swift_name("singleton")));
@property (class, readonly) SharedKoin_coreKind *factory __attribute__((swift_name("factory")));
@property (class, readonly) SharedKoin_coreKind *scoped __attribute__((swift_name("scoped")));
+ (SharedKotlinArray<SharedKoin_coreKind *> *)values __attribute__((swift_name("values()")));
@property (class, readonly) NSArray<SharedKoin_coreKind *> *entries __attribute__((swift_name("entries")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreCallbacks")))
@interface SharedKoin_coreCallbacks<T> : SharedBase
- (instancetype)initWithOnClose:(void (^ _Nullable)(T _Nullable))onClose __attribute__((swift_name("init(onClose:)"))) __attribute__((objc_designated_initializer));
- (SharedKoin_coreCallbacks<T> *)doCopyOnClose:(void (^ _Nullable)(T _Nullable))onClose __attribute__((swift_name("doCopy(onClose:)")));
- (BOOL)isEqual:(id _Nullable)other __attribute__((swift_name("isEqual(_:)")));
- (NSUInteger)hash __attribute__((swift_name("hash()")));
- (NSString *)description __attribute__((swift_name("description()")));
@property (readonly) void (^ _Nullable onClose)(T _Nullable) __attribute__((swift_name("onClose")));
@end

__attribute__((swift_name("Koin_coreKoinExtension")))
@protocol SharedKoin_coreKoinExtension
@required
- (void)onClose __attribute__((swift_name("onClose()")));
- (void)onRegisterKoin:(SharedKoin_coreKoin *)koin __attribute__((swift_name("onRegister(koin:)")));
@end

__attribute__((objc_subclassing_restricted))
__attribute__((swift_name("Koin_coreScopeRegistry.Companion")))
@interface SharedKoin_coreScopeRegistryCompanion : SharedBase
+ (instancetype)alloc __attribute__((unavailable));
+ (instancetype)allocWithZone:(struct _NSZone *)zone __attribute__((unavailable));
+ (instancetype)companion __attribute__((swift_name("init()")));
@property (class, readonly, getter=shared) SharedKoin_coreScopeRegistryCompanion *shared __attribute__((swift_name("shared")));
@end

#pragma pop_macro("_Nullable_result")
#pragma clang diagnostic pop
NS_ASSUME_NONNULL_END
